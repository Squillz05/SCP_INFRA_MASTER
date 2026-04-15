### Workstations Deploy Notes




# command template for destroying types of deployed machines
``` 
tofu destroy \
  -target=openstack_compute_instance_v2.red_kali \
  -target=openstack_compute_instance_v2.red_windows 
```

---


RED TEAM REQUESTS:
Blow up windows: replace with Ubuntu 2404 

6 kali, 3 ubunutu, 1 windows (the forsaken one)

Blue Team requests:
5 ubuntu, 4 windows, 1 void (joke) >:\

Things that need to be done:

- Blue team boxes moved to the blue project (nuhuh)
  
- Red team boxes moved to the red project (yuhuh)

- Make sure that the openstack credentials work for the terraform (never)

- Windows ssh working and fun (dear god end me)

- Blow up red team windoows, give them ubuntu, keep the forsaken one (Done and finished)

- Blue instances are fine just have to be moved (we are NOT doing this one)


------------------------------------------------------------

Red team connectivity test done and dusted
Blue team connectivity test the same

Maybe some user need to be adjusted so that blue team can't just ssh into red team boxes easily

but that's pretty much everything done as of now :smile: