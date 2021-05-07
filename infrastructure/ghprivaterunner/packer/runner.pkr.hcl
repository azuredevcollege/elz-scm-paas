source "azure-arm" "ghrunner" {
  client_id = var.client_id
  client_secret = var.client_secret
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id

  managed_image_name = var.managed_image_name
  managed_image_resource_group_name = var.managed_image_resource_group_name

  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "18.04-LTS"
  image_version = "latest"

  azure_tags = {
    dept = "engineering"
  }

  location = "westeurope"
  vm_size = "Standard_D2s_v3"
}

build {
  sources = ["sources.azure-arm.ghrunner"]

  provisioner "shell" {
    script = "./ghprivaterunner/install.sh"
  }

  provisioner "shell" {
   execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
   inline = [
        "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
   ]
   inline_shebang = "/bin/sh -x"
  }
}