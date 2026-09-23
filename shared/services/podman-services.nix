system.shared.services.podman.containers.vaultwarden = {
    enable = true;
    containerName = "vaultwarden";
    RunAtLoad = true;
    image = [
        "config.ven.vaultwarden.image";
        "vaultwarden/server:1.37.3";
    ];
    hostPort = "8080";
    internalPort = "80";
    dataDir = "<dataDir>";
    domain = "<domain>";
    ip.address = "<ipAddress>";
    logDir = "${paths.darwin.system.tmp}/com.ven.vaultwarden.out.log";
    errorLogDir = "${paths.darwin.system.tmp}/com.ven.vaultwarden.err.log";
}