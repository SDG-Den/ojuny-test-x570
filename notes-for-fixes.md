nix-settings-gui git pull seemingly doesn't work when the flake has multiple branches, must pull branch main. 

development patch projects menu does not work correctly for agent, obsidian or terminal. it ends up in home. both terminal and vscodium end up inside the devshell which is good, both open zsh which is correct. obsidian will also open previously-opened windows, which we do not want. 

rebuilding fails with the following error:

tarting [systemd-run] /nix/store/0aclzqci9b57srwzmxabwkj3azlhr23x-nixos-system-ojuny-26.11.20261121.2786a2a/bin/switch-to-configuration switch...
Started [systemd-run] /nix/store/0aclzqci9b57srwzmxabwkj3azlhr23x-nixos-system-ojuny-26.11.20261121.2786a2a/bin/switch-to-configuration switch.
Checking switch inhibitors... done
Skipping "/boot/EFI/systemd/systemd-bootx64.efi", same boot loader version in place already.
Skipping "/boot/EFI/BOOT/BOOTX64.EFI", same boot loader version in place already.
Traceback (most recent call last):
  File "/nix/store/4pbpcyyyq610jfyflpyzji7hwf8dw0h9-systemd-boot/bin/systemd-boot", line 688, in <module>
    main()
    ~~~~^^
  File "/nix/store/4pbpcyyyq610jfyflpyzji7hwf8dw0h9-systemd-boot/bin/systemd-boot", line 666, in main
    install_bootloader(args)
    ~~~~~~~~~~~~~~~~~~^^^^^^
  File "/nix/store/4pbpcyyyq610jfyflpyzji7hwf8dw0h9-systemd-boot/bin/systemd-boot", line 593, in install_bootloader
    write_loader_conf(default_entry_id)
    ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^
  File "/nix/store/4pbpcyyyq610jfyflpyzji7hwf8dw0h9-systemd-boot/bin/systemd-boot", line 299, in write_loader_conf
    with tmp.open("x") as f:
         ~~~~~~~~^^^^^
  File "/nix/store/bya4ansy58az5133kryqp2cvrxbnz8qy-python3-3.14.10/lib/python3.14/pathlib/__init__.py", line 771, in open
    return io.open(self, mode, buffering, encoding, errors, newline)
           ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
FileExistsError: [Errno 17] File exists: '/boot/loader/loader.tmp'
Failed to install bootloader
nixos-rebuild-switch-to-configuration.service: Main process exited, code=exited, status=1/FAILURE
nixos-rebuild-switch-to-configuration.service: Failed with result 'exit-code'.
Command 'systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER -E NIXOS_NO_CHECK --collect --no-ask-password --quiet --service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait --verbose --output=cat /nix/store/0aclzqci9b57srwzmxabwkj3azlhr23x-nixos-system-ojuny-26.11.20261121.2786a2a/bin/switch-to-configuration switch' returned non-zero exit status 1.

ojuny cli hangs forever instead of replying.

automatic disk mount does not work for all ISO's, nixos iso worked, mint iso did not. mint image 3.1gb, nixos iso tested was under 1gb



