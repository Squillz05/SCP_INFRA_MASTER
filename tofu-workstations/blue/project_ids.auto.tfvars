# Main (Grey) project — Blue BLUE-LIN-* workstations are created here (same tenant as shared infra).
# Use an app credential or openrc scoped to this project only.
main_project_id = "e5c8122da40747928b67b707f5f00961"

boot_network_id = "ec2ac4a5-e5af-464c-bb0c-f65bad9e2f43"

# Blue team Neutron security group (resolved to a name for Nova; attached with base_security_group_names, default "default").
blueteam_security_group_id = "1a97364f-2a60-41df-94a5-9ad1e4ad881c"
