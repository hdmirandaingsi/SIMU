

# entrar a root 

su - 
# registrar  al Usuario 

usermod -aG sudo h-debian


#  El cambio no tiene efecto hasta que sales y vuelves a entrar a tu sesión
#REINICIA!!!

reboot

#es necesario REINICIA!!!



# verificar cambios  
groups h-debian



# ahora necesitamos actulizar las listas REPOSITORIOS para DEBIAN 11 y poder usar APT 
# modificar con ROOT 

nano /etc/apt/sources.list


: <<'FIN_COMENTARIO'   


# Linea del CD-ROM comentada para que no la use
# deb cdrom:[Debian GNU/Linux 11.11.0 _Bullseye_...] bullseye main

# Repositorios principales de Debian
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

# Repositorios de seguridad (muy importantes)
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free

# Repositorios de actualizaciones ("bullseye-updates")
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free

FIN_COMENTARIO  


# luego entrar 
   visudo

# dentro de /etc/sudoers.tmp

# registrar 

   h-debian ALL=(ALL:ALL) ALL


#similar 
# User privilege specification
root     ALL=(ALL:ALL) ALL
h-debian ALL=(ALL:ALL) ALL







# Primero, actualiza la lista de paquetes disponibles
apt update

# Ahora, instala el paquete sudo
apt install sudo

   
   

#vamos con la interfaz  XFCE 

sudo apt update
sudo apt install task-xfce-desktop
sudo reboot


