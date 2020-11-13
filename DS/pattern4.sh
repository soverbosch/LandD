#!/bin/bash

DEPLOYMENTKEY=AINGo0yfN6nxkY5LUxQMuZhwAvbdiA5CBVN1bkVDcCEUfR4iZGZoHA
DEPLOYMENTKEY_PASSWORD=changeit
HOSTNAME=ds.localtest.me

for i in 1 2 3 4 5; do
  # Install the software
  echo "Installing ds${i}"
  dir_name="ds${i}"
  mkdir ${dir_name}
  unzip -q DS-7.0.0.zip -d ${dir_name}
  mv ${dir_name}/opendj/* ${dir_name} && rm -r ${dir_name}/opendj

  # Setup needed variables
  SERVER_ID="ds${i}"
  ADMIN_PORT="${i}4444"
  LDAP_PORT="${i}389"
  LDAPS_PORT="${i}636"
  HTTPS_PORT="${i}8443"
  REPL_PORT="${i}8989"
  SETUP_ARGS="--quiet --acceptLicense \
          --deploymentKey ${DEPLOYMENTKEY} \
          --deploymentKeyPassword ${DEPLOYMENTKEY_PASSWORD} \
          --serverId ${SERVER_ID} \
          --rootUserDn uid=admin \
          --rootUserPassword changeit \
          --monitorUserDn uid=Monitor \
          --monitorUserPassword changeit \
          --hostname ${HOSTNAME} \
          --adminConnectorPort ${ADMIN_PORT} \
          --ldapPort ${LDAP_PORT} \
          --ldapsPort ${LDAPS_PORT} \
          --httpsPort ${HTTPS_PORT} \
          --replicationPort ${REPL_PORT} \
          --profile am-identity-store:7.0.0 \
          --set am-identity-store/amIdentityStoreAdminPassword:changeit \
          --bootstrapReplicationServer ds.localtest.me:18989"

  # Setup the DS instance
  echo "Running setup for ds${i} using ${SETUP_ARGS}"
  ${dir_name}/setup ${SETUP_ARGS}

  # Start the DS instance
  echo "Start ds${i}"
  ${dir_name}/bin/start-ds

  ${dir_name}/bin/dsrepl status --hostname ds.localtest.me --port ${i}4444 --bindDn uid=admin --bindPassword changeit -X --no-prompt --baseDN "ou=identities" --script-friendly --showReplicas --showGroups --showChangelogs

  if [[ ${i} -eq 1 ]]; then
    ${dir_name}/bin/stop-ds
  fi
done

# Print out the replication statusses from all DS instances
for i in 1 2 3 4 5; do
  ds1/bin/dsrepl status --hostname ds.localtest.me --port ${i}4444 --bindDn uid=admin --bindPassword changeit -X --no-prompt --baseDN "ou=identities" --script-friendly --showReplicas --showGroups --showChangelogs
done

# Stop and remove all instances
#for i in 1 2 3 4 5; do
  #ds${i}/bin/stop-ds
  #rm -rf opendj${i}
#done
