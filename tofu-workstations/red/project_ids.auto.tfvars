# Red project only — source app cred openrc scoped to this project before plan/apply.
red_project_id = "7564cb869e4347b49f3ff18cba582102"

# Neutron UUID for the shared main LAN (SCPmainnet). Nova needs this at create time.
# Override if your environment uses a different network.
boot_network_id = "ec2ac4a5-e5af-464c-bb0c-f65bad9e2f43"

# Neutron security group UUID (resolved to a name for Nova); attached with base_security_group_names (default "default").
redteam_security_group_id = "e36b5afe-cab5-476a-adf9-7a3406c662cc"
