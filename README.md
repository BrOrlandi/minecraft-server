# Minecraft Server

### RCON console:

```bash
docker exec -i minecraft-server_mc_1 rcon-cli
```

## Backup

```sh
mkdir ./backups
./backup.sh -a -c minecraft-server-mc-1 -o ./backups -r
```

## Restore

```bash
# stop the container
docker stop minecraft-server-mc-1

# restore the backup
docker run --rm --volumes-from minecraft-server-mc-1 -v $(pwd)/backups/minecraft-server-mc-1:/backup bash -c "cd /data && tar xvf /backup/data_2024-12-25_103705.tar --strip 1"

# start the container
docker start minecraft-server-mc-1
```

## Cron to Backup

```bash
crontab -e
```

```bash
0 3 * * * /path/to/backup.sh -a -c minecraft-server-mc-1 -o /path/to/backups -r
```
