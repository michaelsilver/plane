use crate::{
    client::{PlaneClient, PlaneClientError},
    names::{BackendName, DroneName, Name, ProxyName},
    protocol::{CertManagerRequest, CertManagerResponse, MessageFromProxy, MessageToProxy},
    types::{BackendStatus, ClusterName, ConnectRequest, ExecutorConfig, KeyConfig, SpawnConfig},
    PLANE_GIT_HASH, PLANE_VERSION,
};
use clap::{Parser, Subcommand};
use colored::Colorize;
use url::Url;

fn show_error(error: &PlaneClientError) {
    match error {
        PlaneClientError::Http(error) => {
            eprintln!(
                "{}: {}",
                "HTTP error from API server".bright_red(),
                error.to_string().magenta()
            );
        }
        PlaneClientError::Url(error) => {
            eprintln!(
                "{}: {}",
                "URL error".bright_red(),
                error.to_string().magenta()
            );
        }
        PlaneClientError::Json(error) => {
            eprintln!(
                "{}: {}",
                "JSON error".bright_red(),
                error.to_string().magenta()
            );
        }
        PlaneClientError::UnexpectedStatus(status) => {
            eprintln!(
                "{}: {}",
                "Unexpected status code from API server".bright_red(),
                status.to_string().magenta()
            );
        }
        PlaneClientError::PlaneError(error, status) => {
            eprintln!(
                "{}:\n    Message: {}\n    HTTP status: {}\n    Error ID for correlating with logs: {}",
                "API returned error status".bright_red(),
                error.message.magenta().bold(),
                status.to_string().bright_cyan(),
                error.id.bright_yellow(),
            );
        }
        PlaneClientError::ConnectFailed(message) => {
            eprintln!(
                "{}: {}",
                "Failed to connect to API server".bright_red(),
                message.magenta()
            );
        }
        PlaneClientError::BadConfiguration(message) => {
            eprintln!(
                "{}: {}",
                "Bad configuration".bright_red(),
                message.magenta()
            );
        }
        PlaneClientError::Tungstenite(error) => {
            eprintln!(
                "{}: {}",
                "WebSocket error".bright_red(),
                error.to_string().magenta()
            );
        }
        PlaneClientError::SendFailed => {
            eprintln!("{}", "Failed to send message to channel".bright_red());
        }
    }
}

#[derive(Parser)]
pub struct AdminOpts {
    #[clap(long)]
    controller: Url,

    #[clap(subcommand)]
    command: AdminCommand,
}

#[derive(Subcommand)]
enum AdminCommand {
    Connect {
        #[clap(long)]
        cluster: Option<ClusterName>,

        #[clap(long)]
        image: String,

        #[clap(long)]
        key: Option<String>,

        #[clap(long)]
        immediate: bool,

        /// The number of seconds without any connected clients to wait before terminating the backend.
        #[clap(long)]
        max_idle_seconds: Option<i32>,

        /// An optional backend to assign the string (not recommended and may be removed. Omit to allow Plane to auto-assign
        /// one instead).
        #[clap(long)]
        id: Option<BackendName>,

        /// Use a static connection token for this backend instead of generating them dynamically for each user.
        #[clap(long)]
        static_token: bool,

        /// An optional drone pool (string), used when selecting where to run the backend.
        #[clap(long)]
        pool: Option<String>,
    },
    Terminate {
        #[clap(long)]
        backend: BackendName,

        #[clap(long)]
        hard: bool,

        #[clap(long)]
        immediate: bool,
    },
    Drain {
        #[clap(long)]
        cluster: ClusterName,

        #[clap(long)]
        drone: DroneName,
    },
    PutDummyDns {
        #[clap(long)]
        cluster: ClusterName,
    },
    Status,
}

pub async fn run_admin_command(opts: AdminOpts) {
    if let Err(error) = run_admin_command_inner(opts).await {
        show_error(&error);
        std::process::exit(1);
    }
}

pub async fn run_admin_command_inner(opts: AdminOpts) -> Result<(), PlaneClientError> {
    let client = PlaneClient::new(opts.controller);

    match opts.command {
        AdminCommand::Connect {
            cluster,
            image,
            key,
            immediate,
            max_idle_seconds,
            id,
            static_token,
            pool,
        } => {
            let executor_config = ExecutorConfig::from_image_with_defaults(image);
            let max_idle_seconds = max_idle_seconds.unwrap_or(500);
            let spawn_config = SpawnConfig {
                id,
                cluster: cluster.clone(),
                executable: executor_config.clone(),
                lifetime_limit_seconds: None,
                max_idle_seconds: Some(max_idle_seconds),
                use_static_token: static_token,
            };
            let key_config = key.map(|name| KeyConfig {
                name,
                ..Default::default()
            });
            let spawn_request = ConnectRequest {
                spawn_config: Some(spawn_config),
                key: key_config,
                pool,
                ..Default::default()
            };

            let response = client.connect(&spawn_request).await?;

            if response.spawned {
                println!(
                    "Created backend: {}",
                    response.backend_id.to_string().bright_green()
                );
            } else {
                println!(
                    "Reusing backend: {}",
                    response.backend_id.to_string().bright_green()
                );
            }

            println!("URL: {}", response.url.bright_white());
            println!("Status URL: {}", response.status_url.bright_white());

            if let Some(drone) = response.drone {
                println!("Drone: {}", drone.to_string().bright_green());
            }

            if !immediate {
                let mut stream = client.backend_status_stream(&response.backend_id).await?;

                while let Some(status) = stream.next().await {
                    println!(
                        "Status: {} at {}",
                        status.status.to_string().magenta(),
                        status.time.0.to_string().bright_cyan()
                    );

                    if status.status >= BackendStatus::Ready {
                        break;
                    }
                }
            }
        }
        AdminCommand::Terminate {
            backend,
            hard,
            immediate,
        } => {
            if hard {
                client.hard_terminate(&backend).await?
            } else {
                client.soft_terminate(&backend).await?
            };

            println!(
                "Sent termination signal {}",
                backend.to_string().bright_green()
            );

            if !immediate {
                let mut stream = client.backend_status_stream(&backend).await?;

                while let Some(status) = stream.next().await {
                    println!(
                        "Status: {} at {}",
                        status.status.to_string().magenta(),
                        status.time.0.to_string().bright_cyan()
                    );

                    if status.status >= BackendStatus::Terminated {
                        break;
                    }
                }
            }
        }
        AdminCommand::Drain { cluster, drone } => {
            client.drain(&cluster, &drone).await?;
            println!("Sent drain signal to {}", drone.to_string().bright_green());
        }
        AdminCommand::Status => {
            let status = client.status().await?;
            println!("Status: {}", status.status.to_string().bright_cyan());

            let client_version = if status.version == PLANE_VERSION {
                PLANE_VERSION.bright_green()
            } else {
                PLANE_VERSION.bright_yellow()
            };

            let client_hash = if status.hash == PLANE_GIT_HASH {
                PLANE_GIT_HASH.bright_green()
            } else {
                PLANE_GIT_HASH.bright_yellow()
            };

            println!(
                "Version: {} (client: {})",
                status.version.bright_white(),
                client_version
            );
            println!(
                "Hash: {} (client: {})",
                status.hash.bright_white(),
                client_hash
            );
        }
        AdminCommand::PutDummyDns { cluster } => {
            let connection = client.proxy_connection(&cluster);
            let proxy_name = ProxyName::new_random();
            let mut conn = connection.connect(&proxy_name).await?;

            conn.send(MessageFromProxy::CertManagerRequest(
                CertManagerRequest::CertLeaseRequest,
            ))
            .await?;

            let response = conn.recv().await.expect("Failed to receive response");

            match response {
                MessageToProxy::CertManagerResponse(CertManagerResponse::CertLeaseResponse {
                    accepted,
                }) => {
                    if accepted {
                        tracing::info!("Leased dummy DNS.");
                    } else {
                        tracing::error!("Failed to lease dummy DNS.");
                    }
                }
                _ => panic!("Unexpected response"),
            }

            let message = format!("Dummy message from {}", proxy_name);

            conn.send(MessageFromProxy::CertManagerRequest(
                CertManagerRequest::SetTxtRecord {
                    txt_value: message.clone(),
                },
            ))
            .await?;

            let response = conn.recv().await.expect("Failed to receive response");

            match response {
                MessageToProxy::CertManagerResponse(
                    CertManagerResponse::SetTxtRecordResponse { accepted },
                ) => {
                    if accepted {
                        tracing::info!(?message, "Sent dummy DNS message.");
                    } else {
                        tracing::error!(?message, "Failed to set DNS message.");
                    }
                }
                _ => panic!("Unexpected response"),
            }
        }
    };

    Ok(())
}
