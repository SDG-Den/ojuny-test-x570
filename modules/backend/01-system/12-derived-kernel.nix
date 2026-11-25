{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  choice = "Derived Minimal (Experimental)";

  components = {
    boot = {
      core = true;
      symbols = [
        "MODULES"
        "BLK_DEV_INITRD"
        "DEVTMPFS"
        "BINFMT_ELF"
        "BINFMT_SCRIPT"
        "PROC_FS"
        "SYSFS"
        "TMPFS"
        "VT"
        "FRAMEBUFFER_CONSOLE"
        "SERIAL_8250"
        "IKCONFIG"
        "IKCONFIG_PROC"
      ];
    };

    system = {
      core = true;
      symbols = [
        "CGROUPS"
        "CGROUP_SCHED"
        "CGROUP_CPUACCT"
        "CGROUP_DEVICE"
        "CGROUP_FREEZER"
        "CGROUP_PIDS"
        "MEMCG"
        "SECCOMP"
        "SECCOMP_FILTER"
        "USER_NS"
        "FHANDLE"
        "BPF_SYSCALL"
        "POSIX_MQUEUE"
        "AIO"
        "SYSVIPC"
      ];
    };

    bus = {
      core = true;
      symbols = [
        "PCI"
        "ACPI"
        "EFI"
        "EFI_STUB"
        "USB"
        "INPUT"
        "HID"
        "HID_GENERIC"
        "INPUT_EVDEV"
        "INPUT_KEYBOARD"
        "INPUT_MOUSE"
      ];
    };

    display = {
      core = true;
      symbols = [
        "DRM"
        "DRM_SIMPLEDRM"
        "DRM_FBDEV_EMULATION"
        "FB"
        "FRAMEBUFFER_CONSOLE"
        "VGA_SWITCHEROO"
      ];
    };

    crypto = {
      core = true;
      symbols = [
        "CRYPTO"
        "CRYPTO_HASH"
        "CRYPTO_SKCIPHER"
        "MODULE_SIG"
        "SYSTEM_TRUSTED_KEYRING"
        "SYSTEM_BLACKLIST_KEYRING"
        "SECONDARY_TRUSTED_KEYRING"
      ];
    };

    storageCore = {
      core = true;
      drivers = [ "dm_mod" "loop" ];
      symbols = [
        "BLK_DEV"
        "BLK_DEV_LOOP"
        "BLK_DEV_DM"
      ];
    };

    netCore = {
      core = true;
      symbols = [
        "NET"
        "UNIX"
        "INET"
        "PACKET"
        "NETFILTER"
        "NETFILTER_ADVANCED"
        "NETFILTER_XTABLES"
        "NF_TABLES"
        "NF_CONNTRACK"
        "NF_TABLES_IPV4"
        "NF_TABLES_IPV6"
        "NF_TABLES_INET"
        "NF_TABLES_ARP"
        "NET_SCHED"
      ];
    };

    hw = {
      core = true;
      symbols = [
        "THERMAL"
        "HWMON"
        "CPU_FREQ"
        "ACPI_THERMAL"
        "WATCHDOG"
        "WATCHDOG_CORE"
        "SERIAL_8250"
      ];
    };

    security = {
      core = true;
      symbols = [
        "HARDENED_USERCOPY"
        "RANDOMIZE_BASE"
        "STRICT_KERNEL_RWX"
        "STRICT_MODULE_RWX"
        "SECURITY_YAMA"
        "SECURITY_LANDLOCK"
        "SECURITY_APPARMOR"
        "DEFAULT_SECURITY_APPARMOR"
        "SECURITY_LOCKDOWN_LSM"
        "SECURITY_LOCKDOWN_LSM_EARLY"
        "SECURITY_DMESG_RESTRICT"
        "FORTIFY_SOURCE"
        "SLAB_FREELIST_HARDENED"
        "SLAB_FREELIST_RANDOM"
        "INIT_ON_ALLOC_DEFAULT_ON"
        "RANDOMIZE_KSTACK_OFFSET_DEFAULT"
        "SHUFFLE_PAGE_ALLOCATOR"
        "PAGE_POISONING"
        "BUG"
        "BUG_ON_DATA_CORRUPTION"
        "LIST_HARDENED"
        "X86_USER_SHADOW_STACK"
        "MITIGATION_SLS"
        "IMA"
        "INTEGRITY_SIGNATURE"
        "INTEGRITY_ASYMMETRIC_KEYS"
        "INTEGRITY_PLATFORM_KEYRING"
        "INTEGRITY_MACHINE_KEYRING"
        "CRYPTO_ECDSA"
        "TCG_TPM"
        "TCG_CRB"
        "TCG_TIS"
      ];
      enableSymbols = {
        TCG_TPM = "y";
        TCG_CRB = "m";
        TCG_TIS = "m";
      };
    };

    usb = {
      default = true;
      drivers = [
        "usbhid"
        "usb_storage"
        "xhci_hcd"
        "xhci_pci"
        "ehci_hcd"
        "ehci_pci"
        "ohci_hcd"
        "ohci_pci"
        "uhci_hcd"
        "hid_generic"
        "hid_lenovo"
        "hid_apple"
        "hid_roccat"
        "hid_logitech_hidpp"
        "hid_logitech_dj"
        "hid_microsoft"
        "hid_cherry"
        "hid_corsair"
      ];
      symbols = [
        "USB_XHCI_HCD"
        "USB_XHCI_PCI"
        "USB_EHCI_HCD"
        "USB_EHCI_PCI"
        "USB_OHCI_HCD"
        "USB_OHCI_HCD_PCI"
        "USB_UHCI_HCD"
        "USB_HID"
        "USB_HIDDEV"
        "USB_STORAGE"
        "USB_UAS"
        "USB_XHCI_PCI_PROM21"
      ];
      enableSymbols = {
        USB_OHCI_HCD = "m";
        USB_OHCI_HCD_PCI = "m";
        USB_XHCI_PCI_PROM21 = "m";
      };
    };

    ps2 = {
      default = true;
      drivers = [ "atkbd" "i8042" "pcips2" ];
      symbols = [
        "SERIO_I8042"
        "SERIO_PCIPS2"
        "KEYBOARD_ATKBD"
        "MOUSE_PS2"
        "MOUSE_PS2_ELANTECH"
        "MOUSE_PS2_SYNAPTICS"
        "MOUSE_PS2_VMMOUSE"
      ];
      enableSymbols = {
        SERIO = "y";
        SERIO_PCIPS2 = "m";
      };
    };

    storageSata = {
      default = true;
      drivers = [ "ahci" "ata_piix" "sata_nv" "sata_via" "sata_sis" "sata_uli" "pata_marvell" ];
      symbols = [
        "ATA"
        "ATA_PIIX"
        "SATA_AHCI"
        "SATA_NV"
        "SATA_VIA"
        "SATA_SIS"
        "SATA_ULI"
        "PATA_MARVELL"
        "ATA_GENERIC"
      ];
    };

    scsiDisk = {
      default = true;
      drivers = [ "sd_mod" "sr_mod" ];
      symbols = [
        "SCSI"
        "BLK_DEV_SD"
        "BLK_DEV_SR"
      ];
    };

    nvme = {
      default = true;
      drivers = [ "nvme" ];
      symbols = [ "BLK_DEV_NVME" ];
    };

    sdMmc = {
      default = true;
      drivers = [ "mmc_block" ];
      classes = [ "mmc_controller" ];
      symbols = [
        "MMC"
        "MMC_BLOCK"
        "MMC_SDHCI"
        "MMC_SDHCI_PCI"
        "MMC_SDHCI_ACPI"
        "MMC_SDHCI_PLTFM"
      ];
    };

    filesystemsCommon = {
      default = true;
      drivers = [ "ext2" "ext4" "vfat" "fat" "exfat" "ntfs3" "f2fs" "xfs" "btrfs" "squashfs" "isofs" "udf" "fuse" "autofs" "nls_cp437" "nls_iso8859_1" "nls_utf8" ];
      symbols = [
        "EXT2_FS"
        "EXT4_FS"
        "VFAT_FS"
        "FAT_FS"
        "EXFAT_FS"
        "NTFS3_FS"
        "F2FS_FS"
        "XFS_FS"
        "BTRFS_FS"
        "SQUASHFS"
        "ISO9660_FS"
        "UDF_FS"
        "FUSE_FS"
        "AUTOFS_FS"
        "NLS_CODEPAGE_437"
        "NLS_ISO8859_1"
        "NLS_UTF8"
      ];
    };

    audio = {
      default = true;
      drivers = [ "snd_hda_intel" "snd_usb_audio" ];
      symbols = [
        "SND"
        "SND_HDA"
        "SND_HDA_INTEL"
        "SND_HDA_CODEC_HDMI"
        "SND_HDA_CODEC_REALTEK"
        "SND_HDA_CODEC_ANALOG"
        "SND_HDA_PATCH_LOADER"
        "SND_HDA_INPUT_BEEP"
        "SND_HDA_RECONFIG"
        "SND_USB"
        "SND_USB_AUDIO"
        "SND_PCI"
      ];
    };

    swap = {
      default = true;
      symbols = [ "SWAP" ];
    };

    watchdog = {
      default = true;
      symbols = [ "WATCHDOG" "WATCHDOG_CORE" ];
    };

    sensors = {
      default = true;
      drivers = [ "k10temp" "coretemp" "nct6775" "it87" ];
      symbols = [
        "SENSORS_K10TEMP"
        "SENSORS_CORETEMP"
        "SENSORS_NCT6775"
        "SENSORS_IT87"
      ];
    };

    i2cPiix4 = {
      default = true;
      drivers = [ "i2c_piix4" ];
      symbols = [ "I2C" "I2C_PIIX4" ];
    };

    pcieport = {
      default = true;
      drivers = [ "pcieport" ];
      symbols = [ "PCIEPORTBUS" "HOTPLUG_PCI_PCIE" ];
    };

    binfmtMisc = {
      default = true;
      symbols = [ "BINFMT_MISC" ];
    };

    ethernetR8169 = {
      default = true;
      drivers = [ "r8169" ];
      symbols = [ "R8169" ];
    };

    ethernetIntel = {
      default = true;
      drivers = [ "e1000e" "igb" "igc" ];
      symbols = [ "E1000E" "IGB" "IGC" ];
    };

    ethernetIntel10g = {
      drivers = [ "ixgbe" "i40e" "ice" ];
      symbols = [ "IXGBE" "I40E" "ICE" ];
    };

    ethernetBroadcom = {
      drivers = [ "tg3" "bnx2" "bnx2x" "cnic" ];
      symbols = [ "NET_VENDOR_BROADCOM" "TG3" "BNX2" "BNX2X" "CNIC" ];
      keepSymbols = [ "BNX2" "BNX2X" "CNIC" ];
    };

    ethernetAquantia = {
      drivers = [ "atlantic" ];
      symbols = [ "ATLANTIC" ];
    };

    ethernetMellanox = {
      drivers = [ "mlx5_core" "mlx4_en" ];
      symbols = [ "MLX5_CORE" "MLX5_CORE_EN" "MLX4_EN" ];
    };

    ethernetLegacy = {
      drivers = [ "8139too" "8139cp" "ne2k_pci" "pcnet32" "via_rhine" "sis900" "tulip" "sundance" "dl2k" "fealnx" "natsemi" "starfire" "yellowfin" "hamachi" "tmspci" "uli526x" "de2104x" "de4x5" "dmfe" "winbond_840" ];
      symbols = [
        "8139TOO"
        "8139CP"
        "NE2K_PCI"
        "PCNET32"
        "VIA_RHINE"
        "SIS900"
        "TULIP"
        "SUNDANCE"
        "DL2K"
        "FEALNX"
        "NATSEMI"
        "STARFIRE"
        "YELLOWFIN"
        "HAMACHI"
        "TMSPCI"
        "ULI526X"
        "DE2104X"
        "DE4X5"
        "DMFE"
        "WINBOND_840"
      ];
    };

    usbNet = {
      drivers = [ "rndis_host" "cdc_ether" "cdc_ncm" "usbnet" ];
      symbols = [
        "USB_USBNET"
        "USB_NET_CDCETHER"
        "USB_NET_CDC_NCM"
        "USB_NET_CDC_SUBSET"
        "USB_NET_RNDIS_HOST"
      ];
    };

    usbSerial = {
      drivers = [ "usbserial" "cdc_acm" "ch341" "cp210x" "ftdi_sio" "pl2303" "option" ];
      symbols = [
        "USB_SERIAL"
        "USB_ACM"
        "USB_SERIAL_CH341"
        "USB_SERIAL_CP210X"
        "USB_SERIAL_FTDI_SIO"
        "USB_SERIAL_PL2303"
        "USB_SERIAL_OPTION"
        "USB_SERIAL_WWAN"
      ];
    };

    wifi = {
      implies = [ "staging" ];
      classes = [ "wlan_card" ];
      drivers = [
        "iwlwifi"
        "iwlmvm"
        "ath9k"
        "ath10k_pci"
        "ath11k_pci"
        "ath12k_pci"
        "rtw88_8822be"
        "rtw88_8822ce"
        "rtw88_8821ce"
        "rtw88_8723de"
        "rtw88_8821cs"
        "rtw88_8703b"
        "rtw89_8851be"
        "rtw89_8852ae"
        "rtw89_8852be"
        "rtw89_8852ce"
        "rtl8xxxu"
        "r8188eu"
        "r8712u"
        "mt76"
        "mt7601u"
        "mt76x0u"
        "mt76x2e"
        "mt76x2u"
        "mt7921e"
        "mt7921u"
        "mt7922e"
        "mt7925e"
        "mt7925u"
        "brcmfmac"
        "mwifiex"
        "rt2400pci"
        "rt2500pci"
        "rt2500usb"
        "rt2800pci"
        "rt2800usb"
        "rt61pci"
        "rt73usb"
        "libertas"
        "libertas_tf"
        "wl12xx"
        "wl18xx"
        "cw1200"
        "rtl8187"
        "rtl8180"
        "rtl8192ce"
        "rtl8192de"
        "rtl8192se"
        "rtl8192cu"
        "rtl8192du"
        "rtl8192ee"
        "rtl8192eu"
        "rtl8723ae"
        "rtl8723be"
        "rtl8723cs"
        "rtl8723de"
        "rtl8723ds"
        "rtl8723du"
        "rtl8821ae"
        "rtl8821cu"
        "rndis_wlan"
      ];
      symbols = [
        "CFG80211"
        "MAC80211"
        "RFKILL"
        "RFKILL_INPUT"
        "CFG80211_WEXT"
        "WLAN"
        "WIRELESS"
        "WLAN_VENDOR_INTEL"
        "IWLMVM"
        "IWLWIFI"
        "ATH9K"
        "ATH10K"
        "ATH10K_PCI"
        "ATH11K"
        "ATH11K_PCI"
        "ATH12K"
        "ATH12K_PCI"
        "RTW88"
        "RTW88_8822BE"
        "RTW88_8822CE"
        "RTW88_8821CE"
        "RTW88_8723DE"
        "RTW88_8821CS"
        "RTW88_8703B"
        "RTW89"
        "RTW89_8851BE"
        "RTW89_8852AE"
        "RTW89_8852BE"
        "RTW89_8852CE"
        "RTL8XXXU"
        "R8188EU"
        "R8712U"
        "MT76"
        "MT7601U"
        "MT76X0U"
        "MT76X2E"
        "MT76X2U"
        "MT7921E"
        "MT7921U"
        "MT7922E"
        "MT7925E"
        "MT7925U"
        "BRCMFMAC"
        "MWIFIEX"
        "RT2400PCI"
        "RT2500PCI"
        "RT2500USB"
        "RT2800PCI"
        "RT2800USB"
        "RT61PCI"
        "RT73USB"
        "LIBERTAS"
        "LIBERTAS_TF"
        "WL12XX"
        "WL18XX"
        "CW1200"
        "RTL8187"
        "RTL8180"
        "RTL8192CE"
        "RTL8192DE"
        "RTL8192SE"
        "RTL8192CU"
        "RTL8192DU"
        "RTL8192EE"
        "RTL8192EU"
        "RTL8723AE"
        "RTL8723BE"
        "RTL8723CS"
        "RTL8723DE"
        "RTL8723DS"
        "RTL8723DU"
        "RTL8821AE"
        "RTL8821CU"
        "USB_NET_RNDIS_WLAN"
      ];
    };

    bluetooth = {
      classes = [ "bluetooth" ];
      drivers = [ "btusb" "btbcm" "btintel" "btrtl" "btmtk" "hci_uart" "hci_vhci" "rfcomm" ];
      symbols = [
        "BT"
        "RFKILL"
        "RFKILL_INPUT"
        "BT_HCIBTUSB"
        "BT_HCIBTUSB_AUTOSUSPEND"
        "BT_HCIBTUSB_MTK"
        "BT_HCIUART"
        "BT_HCIUART_BCM"
        "BT_HCIUART_BCSP"
        "BT_HCIUART_H4"
        "BT_HCIUART_LL"
        "BT_HCIUART_QCA"
        "BT_HCIUART_SERDEV"
        "BT_RFCOMM"
        "BT_RFCOMM_TTY"
        "BT_QCA"
        "BT_HCIVHCI"
        "BT_MRVL"
        "BT_MTKSDIO"
      ];
    };

    webcam = {
      classes = [ "camera" ];
      drivers = [ "uvcvideo" ];
      symbols = [
        "MEDIA_SUPPORT"
        "MEDIA_CAMERA_SUPPORT"
        "MEDIA_USB_SUPPORT"
        "USB_VIDEO_CLASS"
        "VIDEO_DEV"
      ];
    };

    gamepad = {
      classes = [ "joystick" ];
      drivers = [ "xpad" "joydev" "hid_sony" "hid_playstation" "hid_nintendo" "hid_steam" ];
      symbols = [
        "INPUT_JOYSTICK"
        "INPUT_JOYDEV"
        "JOYSTICK_XPAD"
        "JOYSTICK_XPAD_FF"
        "JOYSTICK_XPAD_LEDS"
        "HID_SONY"
        "HID_PLAYSTATION"
        "HID_NINTENDO"
        "HID_STEAM"
      ];
    };

    printer = {
      classes = [ "printer" ];
      drivers = [ "usblp" "ppdev" "parport_pc" ];
      symbols = [
        "USB_PRINTER"
        "PPDEV"
        "PARPORT"
        "PARPORT_PC"
      ];
    };

    luks = {
      drivers = [ "dm_crypt" ];
      symbols = [
        "DM_CRYPT"
        "DM_INTEGRITY"
        "CRYPTO_AES"
        "CRYPTO_XTS"
        "CRYPTO_CBC"
        "CRYPTO_LRW"
        "CRYPTO_SHA1"
        "CRYPTO_SHA256"
        "CRYPTO_SHA512"
        "CRYPTO_BLOWFISH"
        "CRYPTO_TWOFISH"
        "CRYPTO_SERPENT"
        "CRYPTO_USER_API_SKCIPHER"
        "CRYPTO_USER_API_HASH"
      ];
      keepSymbols = [
        "CRYPTO_AES"
        "CRYPTO_XTS"
        "CRYPTO_CBC"
        "CRYPTO_LRW"
        "CRYPTO_SHA1"
        "CRYPTO_SHA256"
        "CRYPTO_SHA512"
        "CRYPTO_BLOWFISH"
        "CRYPTO_TWOFISH"
        "CRYPTO_SERPENT"
        "CRYPTO_USER_API_SKCIPHER"
        "CRYPTO_USER_API_HASH"
      ];
    };

    lvm = {
      drivers = [ "dm_snapshot" "dm_mirror" "dm_raid" ];
      implies = [ "raid" ];
      symbols = [
        "DM_SNAPSHOT"
        "DM_MIRROR"
        "DM_RAID"
        "DM_THIN_PROVISIONING"
        "DM_CACHE"
      ];
    };

    raid = {
      drivers = [ "md_mod" ];
      symbols = [
        "BLK_DEV_MD"
        "MD_RAID0"
        "MD_RAID1"
        "MD_RAID10"
        "MD_RAID456"
      ];
    };

    zram = {
      drivers = [ "zram" ];
      symbols = [
        "ZRAM"
        "ZSMALLOC"
        "ZRAM_DEF_COMP_ZSTD"
        "ZRAM_BACKEND_842"
        "ZRAM_BACKEND_DEFLATE"
        "ZRAM_BACKEND_LZ4"
        "ZRAM_BACKEND_LZ4HC"
        "ZRAM_BACKEND_LZO"
        "ZRAM_BACKEND_ZSTD"
        "ZRAM_MULTI_COMP"
        "ZRAM_WRITEBACK"
      ];
    };

    zswap = {
      drivers = [ "zswap" ];
      symbols = [ "ZSWAP" "ZSWAP_COMPRESSOR_DEFAULT_ZSTD" ];
    };

    kvmHost = {
      implies = [ "bridgeVeth" "nfNat" ];
      drivers = [ "kvm" "kvm_amd" "kvm_intel" "vfio" "vfio_pci" "vhost_net" "vhost_vsock" "tun" ];
      symbols = [
        "KVM"
        "KVM_AMD"
        "KVM_INTEL"
        "KVM_VFIO"
        "VFIO"
        "VFIO_PCI"
        "VFIO_IOMMU"
        "VFIO_DEVICE_CDEV"
        "VFIO_NOIOMMU"
        "VFIO_PCI_VGA"
        "X86_SGX_KVM"
        "VHOST_NET"
        "VHOST_VSOCK"
        "TUN"
      ];
      enableSymbols = {
        VIRTUALIZATION = "y";
        KVM = "m";
        KVM_AMD = "m";
        KVM_INTEL = "m";
        VFIO_DEVICE_CDEV = "y";
        VFIO_NOIOMMU = "y";
        VFIO_PCI_VGA = "y";
        X86_SGX_KVM = "y";
      };
    };

    containers = {
      implies = [ "bridgeVeth" "nfNat" "overlayfs" "binfmtMisc" ];
      symbols = [ ];
    };

    virtioGuest = {
      implies = [ "ninep" ];
      drivers = [ "virtio_pci" "virtio_blk" "virtio_net" "virtio_console" "virtio_fs" "virtio_balloon" "virtio_input" "virtio_rng" "virtio_gpu" ];
      symbols = [
        "VIRTIO_PCI"
        "VIRTIO_BLK"
        "VIRTIO_NET"
        "VIRTIO_CONSOLE"
        "VIRTIO_FS"
        "VIRTIO_BALLOON"
        "VIRTIO_INPUT"
        "HW_RANDOM_VIRTIO"
        "SCSI_VIRTIO"
        "DRM_VIRTIO_GPU"
      ];
      enableSymbols = {
        VIRTIO = "m";
        HW_RANDOM_VIRTIO = "m";
      };
    };

    ninep = {
      drivers = [ "9p" "9pnet" "9pnet_virtio" ];
      symbols = [
        "NET_9P"
        "9P_FS"
        "9P_FS_POSIX_ACL"
        "NET_9P_VIRTIO"
        "NET_9P_FD"
      ];
      enableSymbols = {
        NET_9P = "y";
        NET_9P_VIRTIO = "m";
        NET_9P_FD = "m";
      };
    };

    nfs = {
      drivers = [ "nfs" ];
      symbols = [
        "NFS_FS"
        "NFS_V3"
        "NFS_V4"
        "NFS_V4_2"
        "NFS_FSCACHE"
        "NFS_SWAP"
        "NFS_ACL_SUPPORT"
        "SUNRPC"
        "LOCKD"
        "NFSD"
        "NFSD_V3_ACL"
        "NFSD_V4"
        "NFSD_V4_SECURITY_LABEL"
      ];
      keepSymbols = [ "SUNRPC" ];
    };

    cifs = {
      drivers = [ "cifs" ];
      symbols = [
        "CIFS"
        "CIFS_XATTR"
        "CIFS_POSIX"
        "CIFS_FSCACHE"
        "CIFS_UPCALL"
        "CIFS_DFS_UPCALL"
        "SMB_SERVER"
        "SMB_SERVER_KERBEROS5"
      ];
    };

    overlayfs = {
      drivers = [ "overlay" ];
      symbols = [
        "OVERLAY_FS"
        "OVERLAY_FS_REDIRECT_DIR"
        "OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW"
        "OVERLAY_FS_INDEX"
        "OVERLAY_FS_NFS_EXPORT"
        "OVERLAY_FS_METACOPY"
      ];
      enableSymbols = {
        OVERLAY_FS_REDIRECT_DIR = "y";
        OVERLAY_FS_INDEX = "y";
        OVERLAY_FS_METACOPY = "y";
      };
    };

    bcachefs = {
      drivers = [ "bcachefs" ];
      symbols = [ "BCACHEFS_FS" ];
    };

    wireguard = {
      drivers = [ "wireguard" ];
      symbols = [ "WIREGUARD" ];
    };

    nfNat = {
      drivers = [ "nf_nat" "iptable_nat" ];
      symbols = [
        "NF_NAT"
        "IP_NF_NAT"
        "IP6_NF_NAT"
        "NF_NAT_MASQUERADE"
      ];
    };

    bridgeVeth = {
      drivers = [ "bridge" "veth" "macvlan" ];
      symbols = [
        "BRIDGE"
        "VETH"
        "MACVLAN"
        "BRIDGE_VLAN_FILTERING"
        "VLAN_8021Q"
      ];
    };

    firewire = {
      classes = [ "firewire" "firewire_controller" ];
      drivers = [ "firewire_ohci" "firewire_core" "firewire_sbp2" "firewire_net" ];
      symbols = [
        "FIREWIRE"
        "FIREWIRE_OHCI"
        "FIREWIRE_SBP2"
        "FIREWIRE_NET"
      ];
    };

    pcmcia = {
      classes = [ "pcmcia" "pcmcia_controller" ];
      drivers = [ "pcmcia" "yenta_socket" "pcmcia_core" ];
      symbols = [
        "PCMCIA"
        "PCCARD"
        "YENTA"
      ];
    };

    isdn = {
      classes = [ "isdn_adapter" ];
      drivers = [ "isdn" "mISDN_core" ];
      symbols = [
        "ISDN"
        "MISDN"
        "MISDN_CORE"
      ];
    };

    dsl = {
      classes = [ "dsl_adapter" ];
      symbols = [ ];
    };

    hamradio = {
      drivers = [ "ax25" ];
      symbols = [ "HAMRADIO" "AX25" ];
    };

    dvb = {
      classes = [ "dvb_card" ];
      drivers = [ "dvb_core" ];
      symbols = [
        "MEDIA_SUPPORT"
        "MEDIA_DIGITAL_TV_SUPPORT"
        "DVB_CORE"
      ];
    };

    tv = {
      classes = [ "tv_card" ];
      symbols = [
        "MEDIA_SUPPORT"
        "MEDIA_ANALOG_TV_SUPPORT"
      ];
    };

    floppy = {
      classes = [ "floppy" ];
      drivers = [ "floppy" ];
      symbols = [ "BLK_DEV_FD" ];
    };

    tape = {
      classes = [ "tape" ];
      drivers = [ "scsi_tape" ];
      symbols = [ "SCSI_TAPE" ];
    };

    zip = {
      classes = [ "zip" ];
      symbols = [ "BLK_DEV_IDE" "IDEFLOPPY" ];
    };

    chipcard = {
      classes = [ "chip_card" ];
      symbols = [ ];
    };

    braille = {
      classes = [ "braille" ];
      implies = [ "usbSerial" ];
      symbols = [ ];
    };

    debugInfo = {
      symbols = [
        "DEBUG_INFO"
        "DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT"
        "DEBUG_INFO_BTF"
      ];
      offSymbols = { DEBUG_INFO_NONE = "y"; };
    };

    tracing = {
      symbols = [
        "FTRACE"
        "FUNCTION_TRACER"
        "FTRACE_SYSCALLS"
        "KPROBES"
        "UPROBE_EVENTS"
        "BPF_EVENTS"
        "SCHED_TRACER"
        "STACK_TRACER"
        "DYNAMIC_FTRACE"
        "FUNCTION_GRAPH_RETVAL"
      ];
    };

    staging = {
      symbols = [ "STAGING" "STAGING_MEDIA" ];
    };

    ccp = {
      drivers = [ "ccp" ];
      symbols = [
        "CRYPTO_DEV_CCP"
        "CRYPTO_DEV_CCP_DD"
        "CRYPTO_DEV_SP_CCP"
      ];
    };

    gpuIntel = {
      drivers = [ "i915" ];
      symbols = [ "DRM_I915" ];
    };

    gpuAmd = {
      drivers = [ "amdgpu" "radeon" ];
      symbols = [
        "DRM_AMDGPU"
        "DRM_AMDGPU_SI"
        "DRM_AMDGPU_CIK"
        "DRM_AMD_DC"
        "DRM_AMD_DC_DCN"
        "DRM_AMD_DC_FP"
        "DRM_AMD_DC_HDCP"
        "DRM_AMD_DC_SI"
        "DRM_AMD_ACP"
        "DRM_AMD_SECURE_DISPLAY"
        "DRM_AMD_ISP"
        "DRM_AMDGPU_USERPTR"
        "HSA_AMD"
        "HSA_AMD_P2P"
        "DRM_RADEON"
      ];
    };

    gpuNvidiaNouveau = {
      drivers = [ "nouveau" ];
      symbols = [
        "DRM_NOUVEAU"
        "DRM_NOUVEAU_SVM"
      ];
    };

    nvidiaProprietary = {
      drivers = [ "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];
      symbols = [ ];
    };
  };

  coreSymbols = lib.unique (
    lib.concatMap
      (name: components.${name}.symbols or [ ])
      (lib.filter (name: components.${name}.core or false) (lib.attrNames components))
  );

  moduleComponents = lib.foldl'
    (
      componentsForDriver: name:
      lib.foldl'
        (
          acc: driver:
          acc // { ${driver} = (acc.${driver} or [ ]) ++ [ name ]; }
        )
        componentsForDriver
        (components.${name}.drivers or [ ])
    )
    { }
    (lib.attrNames components);

  classComponents = lib.foldl'
    (
      componentsForClass: name:
      lib.foldl'
        (
          acc: class:
          acc // { ${class} = (acc.${class} or [ ]) ++ [ name ]; }
        )
        componentsForClass
        (components.${name}.classes or [ ])
    )
    { }
    (lib.attrNames components);

  moduleSymbols = {
    "9p" = "9P_FS";
    "9pnet" = "NET_9P";
    "9pnet_virtio" = "NET_9P_VIRTIO";
    ahci = "SATA_AHCI";
    atkbd = "KEYBOARD_ATKBD";
    autofs = "AUTOFS_FS";
    btrfs = "BTRFS_FS";
    ccp = "CRYPTO_DEV_CCP";
    cifs = "CIFS";
    cnic = "CNIC";
    ctr = "CRYPTO_CTR";
    coretemp = "SENSORS_CORETEMP";
    dm_mod = "BLK_DEV_DM";
    ehci_hcd = "USB_EHCI_HCD";
    ehci_pci = "USB_EHCI_PCI";
    efivarfs = "EFIVAR_FS";
    exfat = "EXFAT_FS";
    ext2 = "EXT2_FS";
    ext4 = "EXT4_FS";
    f2fs = "F2FS_FS";
    fuse = "FUSE_FS";
    i2c_piix4 = "I2C_PIIX4";
    i8042 = "SERIO_I8042";
    isofs = "ISO9660_FS";
    iso9660 = "ISO9660_FS";
    it87 = "SENSORS_IT87";
    k10temp = "SENSORS_K10TEMP";
    loop = "BLK_DEV_LOOP";
    nct6775 = "SENSORS_NCT6775";
    nfs = "NFS_FS";
    nls_cp437 = "NLS_CODEPAGE_437";
    ntfs3 = "NTFS3_FS";
    nvme = "BLK_DEV_NVME";
    ohci_hcd = "USB_OHCI_HCD";
    ohci_pci = "USB_OHCI_HCD_PCI";
    overlay = "OVERLAY_FS";
    pcips2 = "SERIO_PCIPS2";
    pcieport = "PCIEPORTBUS";
    rndis_host = "USB_NET_RNDIS_HOST";
    rndis_wlan = "USB_NET_RNDIS_WLAN";
    sd_mod = "BLK_DEV_SD";
    sr_mod = "BLK_DEV_SR";
    squashfs = "SQUASHFS";
    "tpm-crb" = "TCG_CRB";
    "tpm-tis" = "TCG_TIS";
    udf = "UDF_FS";
    uinput = "INPUT_UINPUT";
    uhci_hcd = "USB_UHCI_HCD";
    usb_storage = "USB_STORAGE";
    usbhid = "USB_HID";
    vfat = "VFAT_FS";
    virtiofs = "VIRTIO_FS";
    xfs = "XFS_FS";
    xhci_hcd = "USB_XHCI_HCD";
    xhci_pci = "USB_XHCI_PCI";
    xhci_pci_prom21 = "USB_XHCI_PCI_PROM21";
    nvidia = null;
    nvidia_drm = null;
    nvidia_modeset = null;
    nvidia_uvm = null;
    xpadneo = null;
    zfs = null;
    vboxdrv = null;
  };

in
{
  flake.modules.nixos.system-derived-kernel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      report = config.hardware.facter.report or { };
      hardware = report.hardware or { };

      hardwareValue = name: hardware.${name} or null;

      reportIsList = name: let value = hardwareValue name; in builtins.isList value && value != [ ];

      reportClasses = lib.filter reportIsList (lib.attrNames hardware);

      moduleList =
        config.boot.initrd.availableKernelModules
        ++ config.boot.initrd.kernelModules
        ++ config.boot.kernelModules;

      moduleSymbol =
        module:
        if moduleSymbols ? ${module} then
          moduleSymbols.${module}
        else
          lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] module);

      reportDevices = lib.concatMap (
        name:
        let
          value = hardwareValue name;
        in
        if builtins.isList value then value else [ ]
      ) (lib.attrNames hardware);

      normalizeDriver = driver: lib.replaceStrings [ "-" ] [ "_" ] driver;

      reportDrivers = lib.unique (
        lib.concatMap (
          device:
          (device.driver_modules or [ ])
          ++ lib.optional ((device.driver or "") != "") device.driver
        ) reportDevices
      );

      normalizedDrivers = map normalizeDriver reportDrivers;

      detectedByName =
        name:
        let
          component = components.${name};
          byDriver = lib.any (driver: lib.elem driver normalizedDrivers) (component.drivers or [ ]);
          byClass = lib.any reportIsList (component.classes or [ ]);
        in
        byDriver || byClass;

      detectedActive = lib.filter detectedByName (lib.attrNames components);

      fileSystemTypes = lib.unique (
        map (fs: fs.fsType) (lib.attrValues config.fileSystems)
        ++ lib.attrNames (lib.filterAttrs (_: enabled: enabled) config.boot.supportedFilesystems)
      );

      fsComponents = {
        ext2 = [ "filesystemsCommon" ];
        ext3 = [ "filesystemsCommon" ];
        ext4 = [ "filesystemsCommon" ];
        fat = [ "filesystemsCommon" ];
        vfat = [ "filesystemsCommon" ];
        msdos = [ "filesystemsCommon" ];
        exfat = [ "filesystemsCommon" ];
        ntfs = [ "filesystemsCommon" ];
        ntfs3 = [ "filesystemsCommon" ];
        f2fs = [ "filesystemsCommon" ];
        xfs = [ "filesystemsCommon" ];
        btrfs = [ "filesystemsCommon" ];
        squashfs = [ "filesystemsCommon" ];
        iso9660 = [ "filesystemsCommon" ];
        udf = [ "filesystemsCommon" ];
        fuse = [ "filesystemsCommon" ];
        overlay = [ "overlayfs" ];
        nfs = [ "nfs" ];
        nfs4 = [ "nfs" ];
        cifs = [ "cifs" ];
        smb3 = [ "cifs" ];
        "9p" = [ "ninep" ];
        virtiofs = [ "virtioGuest" ];
        bcachefs = [ "bcachefs" ];
        zfs = [ ];
        tmpfs = [ ];
        proc = [ ];
        sysfs = [ ];
        devtmpfs = [ ];
        devpts = [ ];
        ramfs = [ ];
        auto = [ ];
        none = [ ];
        bind = [ ];
      };

      fileSystemActive = lib.concatMap (fsType: fsComponents.${fsType} or [ ]) fileSystemTypes;

      resolvedGpu =
        if config.ojuny.gpu == "auto" then config.ojuny.hardware.gpu.detected else config.ojuny.gpu;

      gpuLayout = if lib.elem resolvedGpu [ "auto" "unknown" ] then "none" else resolvedGpu;

      gpuSources = [
        {
          applies = lib.elem gpuLayout [ "intel" "hybrid-intel-nvidia" "hybrid-intel-amd" ];
          provides = [ "gpuIntel" ];
        }
        {
          applies = lib.elem gpuLayout [ "amd" "hybrid-amd-nvidia" "hybrid-intel-amd" ];
          provides = [ "gpuAmd" ];
        }
        {
          applies =
            lib.elem gpuLayout [ "nvidia" "hybrid-intel-nvidia" "hybrid-amd-nvidia" ]
            && config.ojuny.gpuNvidia.branch == "nouveau";
          provides = [ "gpuNvidiaNouveau" ];
        }
        {
          applies =
            lib.elem gpuLayout [ "nvidia" "hybrid-intel-nvidia" "hybrid-amd-nvidia" ]
            && config.ojuny.gpuNvidia.branch != "nouveau";
          provides = [ "nvidiaProprietary" ];
        }
      ];

      sources =
        [
          {
            applies = config.hardware.bluetooth.enable or false;
            provides = [ "bluetooth" ];
          }
          {
            applies = config.services.printing.enable or false;
            provides = [ "printer" ];
          }
          {
            applies = config.boot.initrd.luks.devices != { };
            provides = [ "luks" ] ++ lib.optional (config.boot.initrd.services.lvm.enable or false) "lvm";
          }
          {
            applies = config.services.lvm.enable or false || config.boot.initrd.services.lvm.enable or false;
            provides = [ "lvm" ];
          }
          {
            applies = config.boot.swraid.enable or false;
            provides = [ "raid" ];
          }
          {
            applies = config.swapDevices != [ ];
            provides = [ "swap" ];
          }
          {
            applies = config.zramSwap.enable or false;
            provides = [ "zram" ];
          }
          {
            applies = config.boot.zswap.enable or false;
            provides = [ "zswap" ];
          }
          {
            applies = config.virtualisation.libvirtd.enable or false || config.programs.virt-manager.enable or false;
            provides = [ "kvmHost" ];
          }
          {
            applies =
              config.virtualisation.docker.enable or false
              || config.virtualisation.podman.enable or false
              || (config.virtualisation.oci-containers.containers or { }) != { };
            provides = [ "containers" ];
          }
          {
            applies =
              config.services.qemuGuest.enable or false
              || config.virtualisation.hypervGuest.enable or false
              || config.virtualisation.vmware.guest.enable or false;
            provides = [ "virtioGuest" ];
          }
          {
            applies = config.services.brltty.enable or false;
            provides = [ "braille" ];
          }
          {
            applies = config.programs.steam.enable or false;
            provides = [ "gamepad" ];
          }
          {
            applies = config.ojuny.hardware.xpadneo or false;
            provides = [ "gamepad" ];
          }
          {
            applies = (config.networking.wireguard.interfaces or { }) != { };
            provides = [ "wireguard" ];
          }
          {
            applies = config.ojuny.vpn.wireguard.enable or false;
            provides = [ "wireguard" ];
          }
          {
            applies = config.networking.nat.enable or false;
            provides = [ "nfNat" ];
          }
          {
            applies = (config.networking.bridges or { }) != { };
            provides = [ "bridgeVeth" ];
          }
          {
            applies = config.services.udisks2.enable or false || config.services.devmon.enable or false;
            provides = [ "usb" "sdMmc" "filesystemsCommon" "scsiDisk" ];
          }
          {
            applies = config.networking.wireless.enable or false;
            provides = [ "wifi" ];
          }
          {
            applies = config.virtualisation.containers.enable or false;
            provides = [ "containers" ];
          }
          {
            applies = config.services.nfs.server.enable or false;
            provides = [ "nfs" ];
          }
          {
            applies = config.services.samba.enable or false;
            provides = [ "cifs" ];
          }
          {
            applies = config.services.btrfs.autoScrub.enable or false;
            provides = [ "filesystemsCommon" ];
          }
          {
            applies = lib.any (
              package: lib.elem (lib.getName package) [ "bpftrace" "bcc" "perf" ]
            ) config.environment.systemPackages;
            provides = [ "debugInfo" "tracing" ];
          }
          {
            applies = true;
            provides = fileSystemActive;
          }
          {
            applies = true;
            provides = lib.concatMap (
              module: moduleComponents.${normalizeDriver module} or [ ]
            ) moduleList;
          }
        ]
        ++ gpuSources;

      sourceActive = lib.concatMap (source: if source.applies then source.provides else [ ]) sources;

      toggleComponents = {
        wifi = [ "wifi" ];
        usbNetworking = [ "usbNet" ];
        webcam = [ "webcam" ];
        gamepad = [ "gamepad" ];
        bluetooth = [ "bluetooth" ];
        printing = [ "printer" ];
        luks = [ "luks" ];
        networkFilesystems = [ "nfs" "cifs" "ninep" ];
        legacyHardware = [
          "firewire"
          "pcmcia"
          "isdn"
          "dsl"
          "hamradio"
          "dvb"
          "tv"
          "floppy"
          "tape"
          "zip"
          "chipcard"
          "braille"
        ];
        debugTracing = [ "debugInfo" "tracing" ];
      };

      toggleActive = lib.concatMap (
        name:
        if config.ojuny.derivedKernel.${name} or false then toggleComponents.${name} else [ ]
      ) (lib.attrNames toggleComponents);

      coreActive = lib.filter (name: components.${name}.core or false) (lib.attrNames components);
      defaultActive = lib.filter (name: components.${name}.default or false) (lib.attrNames components);

      activeSeeds = lib.unique (
        coreActive ++ defaultActive ++ detectedActive ++ sourceActive ++ toggleActive
      );

      impliesClosure =
        active:
        let
          next = lib.unique (
            active ++ lib.concatMap (name: components.${name}.implies or [ ]) active
          );
        in
        if next == active then active else impliesClosure next;

      activeComponents = impliesClosure activeSeeds;

      activeSymbols = lib.unique (
        lib.concatMap (
          name:
          (components.${name}.symbols or [ ])
          ++ (lib.attrNames (components.${name}.enableSymbols or { }))
        ) activeComponents
      );

      allSymbols = lib.unique (
        lib.concatMap (name: components.${name}.symbols or [ ]) (lib.attrNames components)
      );

      moduleKeep = lib.concatMap (
        module:
        let
          symbol = moduleSymbol module;
        in
        if symbol == null then [ ] else [ symbol ]
      ) moduleList;

      keepSymbols = lib.unique (
        lib.concatMap (name: components.${name}.keepSymbols or [ ]) (lib.attrNames components)
        ++ moduleKeep
      );

      disabledSymbols = lib.filter (
        symbol: !(lib.elem symbol activeSymbols) && !(lib.elem symbol keepSymbols)
      ) allSymbols;

      inactiveComponents = lib.filter (name: !(lib.elem name activeComponents)) (lib.attrNames components);

      kernelValue =
        value:
        if value == "y" then
          lib.kernel.yes
        else if value == "m" then
          lib.kernel.module
        else
          lib.kernel.no;

      offEntries = lib.concatMap (
        name:
        lib.mapAttrsToList (symbol: value: { inherit symbol value; }) (components.${name}.offSymbols or { })
      ) inactiveComponents;

      enableEntries = lib.concatMap (
        name:
        lib.mapAttrsToList (symbol: value: { inherit symbol value; }) (components.${name}.enableSymbols or { })
      ) activeComponents;

      mkEntry = entry: lib.nameValuePair entry.symbol (lib.mkForce (lib.kernel.option (kernelValue entry.value)));

      structuredExtraConfig =
        lib.listToAttrs (
          map (
            symbol: lib.nameValuePair symbol (lib.mkForce (lib.kernel.option lib.kernel.no))
          ) disabledSymbols
        )
        // lib.listToAttrs (map mkEntry offEntries)
        // lib.listToAttrs (map mkEntry enableEntries);

      baseKernel = pkgs.linux_7_3;

      customKernel = baseKernel.override {
        structuredExtraConfig = structuredExtraConfig;
        ignoreConfigErrors = true;
      };

      kernelPackages = pkgs.linuxPackagesFor customKernel;
    in
    {
      options.ojuny.derivedKernel = {
        package = lib.mkOption {
          type = lib.types.raw;
          internal = true;
          readOnly = true;
          description = "Package set for the Derived Minimal (Experimental) kernel.";
        };

        activeSymbols = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = true;
          readOnly = true;
          description = "Kernel configuration symbols that the derived kernel keeps.";
        };

        coreSymbols = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = true;
          readOnly = true;
          description = "Kernel configuration symbols that the derived kernel always keeps.";
        };

        moduleSymbols = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
          internal = true;
          readOnly = true;
          description = "Kernel configuration symbol for each module name the derived kernel check inspects.";
        };

        activeComponents = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = true;
          readOnly = true;
          description = "Components active for the current report and settings.";
        };

        reportDrivers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = true;
          readOnly = true;
          description = "Driver names found in the facter report.";
        };

        reportClasses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = true;
          readOnly = true;
          description = "Hardware classes found in the facter report.";
        };

        moduleComponents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          internal = true;
          readOnly = true;
          description = "Component names for each known driver.";
        };

        classComponents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          internal = true;
          readOnly = true;
          description = "Component names for each known report class.";
        };

        wifi = lib.mkEnableOption "Wi-Fi support in the derived kernel";
        usbNetworking = lib.mkEnableOption "USB networking support in the derived kernel";
        webcam = lib.mkEnableOption "webcam support in the derived kernel";
        gamepad = lib.mkEnableOption "gamepad support in the derived kernel";
        bluetooth = lib.mkEnableOption "Bluetooth support in the derived kernel";
        printing = lib.mkEnableOption "printing support in the derived kernel";
        luks = lib.mkEnableOption "LUKS support in the derived kernel";
        networkFilesystems = lib.mkEnableOption "network filesystem support in the derived kernel";
        legacyHardware = lib.mkEnableOption "legacy and rare hardware support in the derived kernel";
        debugTracing = lib.mkEnableOption "kernel debug and tracing support in the derived kernel";
      };

      config = {
        ojuny.derivedKernel.package = kernelPackages;
        ojuny.derivedKernel.activeSymbols = activeSymbols;
        ojuny.derivedKernel.coreSymbols = coreSymbols;
        ojuny.derivedKernel.moduleSymbols = moduleSymbols;
        ojuny.derivedKernel.activeComponents = activeComponents;
        ojuny.derivedKernel.reportDrivers = normalizedDrivers;
        ojuny.derivedKernel.reportClasses = reportClasses;
        ojuny.derivedKernel.moduleComponents = moduleComponents;
        ojuny.derivedKernel.classComponents = classComponents;
      };
    };
}
