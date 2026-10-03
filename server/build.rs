fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .compile_protos(
            &[
                "../protos/episode.proto",
                "../protos/scene.proto",
                "../protos/choice.proto",
                "../protos/action.proto",
                "../protos/progress.proto",
                "../protos/player.proto",
                "../protos/player_choice.proto",
                "../protos/settings.proto",
                "../protos/episode_api.proto",
                "../protos/progress_api.proto",
                "../protos/auth_api.proto",
            ],
            &["../protos"],
        )?;

    Ok(())
}