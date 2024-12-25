# Minecraft Server

### RCON console:

```bash
docker exec -i minecraft-server_mc_1 rcon-cli
```

## Backup

```sh
mkdir ./backups
./backup.sh -a -c minecraft-server_mc_1 -o ./backups -r
```

## Restore

```bash
# stop the container
docker stop minecraft-server_mc_1

# restore the backup
docker run --rm --volumes-from minecraft-server_mc_1 -v $(pwd)/backups/minecraft-server_mc_1:/backup bash -c "cd /data && tar xvf /backup/data_2024-12-25_103705.tar --strip 1"

# start the container
docker start minecraft-server_mc_1
```

## Cron to Backup

```bash
crontab -e
```

```bash
# -d 7: keep 7 days of backups
0 0,12 * * * /home/ubuntu/minecraft-server/backup.sh -a -c minecraft-server_mc_1 -o /home/ubuntu/minecraft-server/backups -r -d 7
```
