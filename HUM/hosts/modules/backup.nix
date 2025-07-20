# /hosts/modules/backup.nix
{ config, pkgs, lib, ... }:
let
  backupConfig = {
    # --- IMPORTANT: REPLACE WITH YOUR BACKUP DISK'S UUID ---
    device = "/dev/disk/by-uuid/BACKUP-DISK-UUID-PLACEHOLDER";
    mountPoint = "/mnt/btrfs-backup";
    sourceSubvolumes = [ "home" "root" ];
    snapshotsToKeep = 7;
  };
  backupScript = pkgs.writeShellScriptBin "btrfs-backup-script" ''
    set -e
    echo "Starting Btrfs backup job..."
    mkdir -p ${backupConfig.mountPoint}
    mount ${backupConfig.device} ${backupConfig.mountPoint}
    for subvol_name in ${lib.concatStringsSep " " backupConfig.sourceSubvolumes}; do
      SOURCE_PATH="/''${subvol_name}"
      SNAPSHOT_DIR="/''${subvol_name}/.snapshots"
      DEST_PATH="${backupConfig.mountPoint}/''${subvol_name}"
      TIMESTAMP=$(date --iso-8601=seconds)
      NEW_SNAPSHOT_NAME="''${subvol_name}-''${TIMESTAMP}"
      echo "Processing subvolume: ''${subvol_name}"
      mkdir -p ''${SNAPSHOT_DIR} ''${DEST_PATH}
      echo "Creating new snapshot: ''${SNAPSHOT_DIR}/''${NEW_SNAPSHOT_NAME}"
      btrfs subvolume snapshot -r ''${SOURCE_PATH} "''${SNAPSHOT_DIR}/''${NEW_SNAPSHOT_NAME}"
      LATEST_ON_DEST=$(find "''${DEST_PATH}" -maxdepth 1 -name "''${subvol_name}-*" -type d | sort -r | head -n 1)
      PARENT_ARGS=""
      if [[ -d "''${LATEST_ON_DEST}" ]]; then
        PARENT_SNAPSHOT_NAME=$(basename "''${LATEST_ON_DEST}")
        if [[ -d "''${SNAPSHOT_DIR}/''${PARENT_SNAPSHOT_NAME}" ]]; then
          PARENT_ARGS="-p \"''${SNAPSHOT_DIR}/''${PARENT_SNAPSHOT_NAME}\""
        fi
      fi
      echo "Sending ''${NEW_SNAPSHOT_NAME} to ''${DEST_PATH}..."
      btrfs send ''${PARENT_ARGS} "''${SNAPSHOT_DIR}/''${NEW_SNAPSHOT_NAME}" | btrfs receive "''${DEST_PATH}"
      find "''${SNAPSHOT_DIR}" -maxdepth 1 -name "''${subvol_name}-*" -type d | sort -r | tail -n +$((${backupConfig.snapshotsToKeep} + 1)) | xargs -r btrfs subvolume delete
      find "''${DEST_PATH}" -maxdepth 1 -name "''${subvol_name}-*" -type d | sort -r | tail -n +$((${backupConfig.snapshotsToKeep} + 1)) | xargs -r btrfs subvolume delete
    done
    umount ${backupConfig.mountPoint}
    echo "Backup job finished successfully."
  '';
in
{
  systemd.services.btrfs-backup = {
    description = "Btrfs Snapshot Backup Service";
    path = [ pkgs.btrfs-progs ];
    script = backupScript.outPath;
    wantedBy = lib.mkForce [ ];
  };
  timers.btrfs-backup = {
    description = "Daily Btrfs Snapshot Backup Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
