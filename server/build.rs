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
                "../protos/episode_api.proto",
            ],
            &["../protos"],
        )?;
    Ok(())
}