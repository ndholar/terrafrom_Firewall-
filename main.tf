provider "azurerm" {
    version = "=1.22.0"

    subscription_id = "${var.subscription-id}"
    client_id       = "${var.client-id}"
    client_secret   = "${var.clientSecrete-id}"
    tenant_id       = "${var.tenant-id}"
    
}

 ## data "azurerm_network_interface" "interface-id" {
  ## name                = "spoke-nic"
  ## resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
## } 
 ## data "azurerm_network_security_group" "NSG" {
  ## name                = "nsg"
 ##  resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
## }


resource "azurerm_resource_group" "RG-DNAT-Test" {
    name = "RG-DNAT-Test"
    location = "${var.location}"
  
}


resource "azurerm_virtual_network" "CORE-VNET" {
    name = "CORE-VNET"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    address_space = ["10.0.0.0/16"]
    location = "${var.location}"
    tags {
        environment = "Firewall Testing"
    }

}
resource "azurerm_subnet" "SN-CORE-01" {
    name = "FWsubnet"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.CORE-VNET.name}"
    address_prefix = "10.0.0.0/24"
  
}

resource "azurerm_virtual_network" "DMZ-VNET" {
    name = "DMZ-VNET"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    address_space = ["192.168.0.0/16"]
    location = "${var.location}"
    tags {
        environment = "Firewall Testing"
    }
}


resource "azurerm_subnet" "SN-DMZ-01" {
    name = "SN-workload"
    address_prefix = "192.168.0.0/24"
    virtual_network_name = "${azurerm_virtual_network.DMZ-VNET.name}"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
  
}

resource "azurerm_virtual_network" "INT-VNET" {
    name = "INT-VNET"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    address_space = ["20.0.0.0/16"]
    location = "${var.location}"
    tags {
        environment = "Firewall Testing"
    }
}


resource "azurerm_subnet" "SN-VNET-01" {
    name = "SN-IIS"
    address_prefix = "20.0.0.0/24"
    virtual_network_name = "${azurerm_virtual_network.INT-VNET.name}"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
  
}

resource "azurerm_virtual_network_peering" "PEER-CORE-DMZ" {
    name = "PEER-CORE-DMZ"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.CORE-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.DMZ-VNET.id}"
  
}


resource "azurerm_virtual_network_peering" "PEER-DMZ-CORE" {
    name = "PEER-DMZ-CORE"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.DMZ-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.CORE-VNET.id}"
}

resource "azurerm_virtual_network_peering" "PEER-CORE-INT" {
    name = "PEER-CORE-INT"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.CORE-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.INT-VNET.id}"
  
}


resource "azurerm_virtual_network_peering" "PEER-INT-CORE" {
    name = "PEER-INT-CORE"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.INT-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.CORE-VNET.id}"
}

resource "azurerm_virtual_network_peering" "PEER-DMZ-INT" {
    name = "PEER-DMZ-INT"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.DMZ-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.INT-VNET.id}"
  
}


resource "azurerm_virtual_network_peering" "PEER-INT-DMZ" {
    name = "PEER-INT-DMZ"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    virtual_network_name = "${azurerm_virtual_network.INT-VNET.name}"
    remote_virtual_network_id = "${azurerm_virtual_network.DMZ-VNET.id}"
}



resource "azurerm_network_security_group" "SpokeNSG" {
    name = "Spokensg"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
    tags {
        environment = "Firewall Testing"
    }

  
}
resource "azurerm_network_interface" "spoke-nic" {
  name                = "FW-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"

  ip_configuration {
    name                          = "IPconfig"
    subnet_id                     = "${azurerm_subnet.SN-DMZ-01.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "Firewall Testing"
  }
}


resource "azurerm_virtual_machine" "DMZ-VM" {
    location = "${var.location}"
    name = "Srv-Workload"
    resource_group_name         = "${azurerm_resource_group.RG-DNAT-Test.name}"
    network_interface_ids       = ["${azurerm_network_interface.spoke-nic.id}"]
    vm_size                     = "standard_B1s"
   
   delete_os_disk_on_termination = true
   delete_data_disks_on_termination = true

   storage_image_reference {

    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"

  }
  storage_os_disk {

    name              = "mydisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }
  os_profile {
    computer_name  = "localhost"
    admin_username = "hpeng"
    admin_password = "Password1234!"
  }

  tags = {
      environment = "Firewall testing "
  }


      
  
}

resource "azurerm_public_ip" "Public-IP" {
  name                = "SubnetPublicIP"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"
  allocation_method   = "dynamic"
  sku                 = "Standard"
}


resource "azurerm_firewall" "FireWall-Test" {
  name                = "testfirewall"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.RG-DNAT-Test.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.SN-CORE-01.id}"
    public_ip_address_id = "${azurerm_public_ip.Public-IP.id}"
  }
}

output "FWPrivate-IP" {
  value = "${azurerm_firewall.FireWall-Test.private_ip_address_allocation.id}"
}

output "DMZ-VM-PIP" {
  value = "${azurerm_virtual_machine.DMZ-VM.private_ip_address_allocation.id}"
}
























