
    // Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
    // Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

      terraform {
        required_version = ">= 0.12.0"
      }

      data "oci_core_subnet" "this" {
        subnet_id = var.subnet_ocid
      }

      data "oci_core_images" "this" {
        #Required
        compartment_id = "${var.compartment_ocid}"
  
        #Optional
        shape = "VM.Standard.E2.1.Micro"
        state = "AVAILABLE"
      }

      # add data source to list AD1 name in the tenancy. Should work for both single and multi Ad region 
      data "oci_identity_availability_domain" "ad" {
          compartment_id = "${var.tenancy_ocid}"
          ad_number      = 1
      }
  
      resource "oci_core_instance" "this" {
        # availability_domain  = data.oci_core_subnet.this.availability_domain
        availability_domain  = "${data.oci_core_subnet.this.availability_domain != null ? data.oci_core_subnet.this.availability_domain : data.oci_identity_availability_domain.ad.name}"
        compartment_id       = var.compartment_ocid
        display_name         = var.instance_display_name
        ipxe_script          = var.ipxe_script
        preserve_boot_volume = var.preserve_boot_volume
        shape                = var.shape

        create_vnic_details {
          assign_public_ip       = var.assign_public_ip
          display_name           = var.vnic_name
          hostname_label         = var.hostname_label
          private_ip             = var.private_ip
          skip_source_dest_check = var.skip_source_dest_check
          subnet_id              = var.subnet_ocid
        }

        metadata = {
          ssh_authorized_keys = var.ssh_public_key
          user_data           = var.user_data
        }

        source_details {
          boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
          source_type = "image"
          source_id   = data.oci_core_images.this.images[0].id
        }

        timeouts {
          create = var.instance_timeout
        }
      }

      resource "oci_core_volume" "this" {
        availability_domain = oci_core_instance.this.availability_domain
        compartment_id      = var.compartment_ocid
        display_name        = "${oci_core_instance.this.display_name}_volume_0"
        size_in_gbs         = var.block_storage_size_in_gbs
      }

      resource "oci_core_volume_attachment" "this" {
        attachment_type = var.attachment_type
        compartment_id  = var.compartment_ocid
        instance_id     = oci_core_instance.this.id
        volume_id       = oci_core_volume.this.id
        use_chap        = var.use_chap
      }
    