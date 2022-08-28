terraform {
	required_providers {
		azurerm = {
			source = "hashicorp/azurerm"
			version = "=2.73.0"
		}
	}
}

provider "azurerm" {
	features {}

	use_msi = true

	subscription_id = "b0387326-5e31-4f92-a146-178320a8d6b5"
	client_id = "6492975e-35e0-42d7-a0dd-756181a499f3"
	tenant_id = "7833d61b-a185-4f1b-8ea2-cf1f9d35de5e"
}

resource "azurerm_resource_group" "TF_ATU_POSTGRESQL_RESOURCE_GRP" {
	name = "ATU_POSTGRESQL_RESOURCE_GRP"
	location = "eastus2"
}

resource "azurerm_virtual_network" "TF_VNET_ATU" {
	name = "VNET_ATU"
	address_space = ["10.1.0.0/16"]
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name

}

resource "azurerm_subnet" "TF_SUBNET_ATU_DATABASE_TIER" {
	name = "SUBNET_ATU_DATABASE_TIER"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	virtual_network_name = azurerm_virtual_network.TF_VNET_ATU.name
	address_prefixes = ["10.1.1.0/24"]

}

resource "azurerm_network_security_group" "TF_SECGRP_ATU_DATABASE_TIER" {
	name = "SECGRP_ATU_DATABASE_TIER"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	security_rule {
		access = "Allow"
		direction = "Inbound"
		name = "tls"
		priority = 100
		protocol = "Tcp"
		source_port_range = "*"
		source_address_prefix = "*"
		destination_port_range = "443"
		destination_address_prefix = "*"
	}
}

resource "azurerm_subnet_network_security_group_association" "TF_SUBNET_SG_ASSOC_SECGRP_ATU_DATABA" {
	subnet_id = azurerm_subnet.TF_SUBNET_ATU_DATABASE_TIER.id
	network_security_group_id = azurerm_network_security_group.TF_SECGRP_ATU_DATABASE_TIER.id
}

resource "azurerm_network_interface" "TF_NIC_INT_VM-ATU-POSTGRESQL-SERVER" {
	name = "NIC_INT_VM-ATU-POSTGRESQL-SERVER"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location

	ip_configuration { 
		name = "internal"
		subnet_id = azurerm_subnet.TF_SUBNET_ATU_DATABASE_TIER.id
		private_ip_address_allocation = "Dynamic"
	}
}

resource "azurerm_managed_disk" "TF_ST_ATU_POSTGRESQL_SERVER_DATA" {
	name = "ST_ATU_POSTGRESQL_SERVER_DATA"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	storage_account_type = "Premium_LRS"
	disk_size_gb = 32
	create_option = "Empty"

}
resource "azurerm_virtual_machine_data_disk_attachment" "disk-attach-1" {
	managed_disk_id = azurerm_managed_disk.TF_ST_ATU_POSTGRESQL_SERVER_DATA.id
	virtual_machine_id = azurerm_linux_virtual_machine.TF_VM-ATU-POSTGRESQL-SERVER.id
	lun = "1"
	caching = "ReadWrite"
}

resource "azurerm_managed_disk" "TF_ST_ATU_POSTGRESQL_SERVER_TEMP" {
	name = "ST_ATU_POSTGRESQL_SERVER_TEMP"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	storage_account_type = "Premium_LRS"
	disk_size_gb = 32
	create_option = "Empty"

}
resource "azurerm_virtual_machine_data_disk_attachment" "disk-attach-2" {
	managed_disk_id = azurerm_managed_disk.TF_ST_ATU_POSTGRESQL_SERVER_TEMP.id
	virtual_machine_id = azurerm_linux_virtual_machine.TF_VM-ATU-POSTGRESQL-SERVER.id
	lun = "2"
	caching = "ReadWrite"
}

resource "azurerm_managed_disk" "TF_ST_ATU_POSTGRESQL_SERVER_LOG" {
	name = "ST_ATU_POSTGRESQL_SERVER_LOG"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	storage_account_type = "Premium_LRS"
	disk_size_gb = 32
	create_option = "Empty"

}
resource "azurerm_virtual_machine_data_disk_attachment" "disk-attach-3" {
	managed_disk_id = azurerm_managed_disk.TF_ST_ATU_POSTGRESQL_SERVER_LOG.id
	virtual_machine_id = azurerm_linux_virtual_machine.TF_VM-ATU-POSTGRESQL-SERVER.id
	lun = "3"
	caching = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "TF_VM-ATU-POSTGRESQL-SERVER" {
	name = "VM-ATU-POSTGRESQL-SERVER"
	resource_group_name = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.name
	location = azurerm_resource_group.TF_ATU_POSTGRESQL_RESOURCE_GRP.location
	size = "Standard_D2s_v4"
	admin_username = "azureadmin"
	admin_password = "azureadmin@12345"
	disable_password_authentication = false
	network_interface_ids = [
		azurerm_network_interface.TF_NIC_INT_VM-ATU-POSTGRESQL-SERVER.id,
	]

	source_image_reference {
		publisher   = "RedHat"
		offer = "RHEL"
		sku = "8-gen2"
		version = "latest"
	}

	os_disk {
		storage_account_type = "Premium_LRS"
		disk_size_gb = 128
		caching = "ReadWrite"
	}
	tags = { 
		environment = "DEV"
		project = "INTEL"
		department = "WORKLOADS"
		owner = "DEVLOPER"
		
	}
}