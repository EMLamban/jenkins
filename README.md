## PROYECTO DE DESPLIEGUE CON DOCKER DE UN SERVIDOR CON JENKINS-ANSIBLE
---

Jenkins en un servidor de automatizaciones ideal para los proyectos de CI/CD, y Ansible es un software de gestión de configuración y despliegue.

La función de un despliegue conjunto de Jenkins y Ansible es para suplir los problemas existentes con el plugin de Jenkins *"SSH"*, etiquetados como altamente vulnerables por las listas **CVE-2022-30958**, **CVE-2022-30959** y **CVE-2022-30957**, resultante de una escalada de privilegios y apropiación de las llaves SSH almacenadas en Jenkins.

De esta manera, para evitar almacenar ninguna llave SSH en Jenkins, se desplegará junto a Ansible en el mismo contenedor, comunicándose Jenkins con Ansible de manera local. Ansible se encargará entonces de comunicarse con las demás máquinas, y será a él a quien le daremos las llaves SSH que necesite para conectar.

Para comenzar con el despliegue, primero deberemos crear manualmente el volumen que contendrá las llaves de ansible en la máquina host:

```
services: 
  jenkins:
    image: jenkins-ansible
    build:
      context: .
      args:
        - ANSIBLE_PASSWORD=${ANSIBLE_PASSWORD}
    container_name: jenkins-ansible
    volumes:
      - $PWD/data/jenkins_home:/var/jenkins_home
      - $PWD/ansible:/home/ansible
    ports:
      - "8080:8080"
    restart: on-failure
```

Para ello, en la raiz del repositorio, lanzaremos el siguiente comando:

`mkdir -p /ansible/.ssh`

Una vez creado, desplegaremos el servicio:

`docker-compose up -d`

Una vez desplegado el servicio, y sólo la primera vez, tendremos que entrar al contenedor de *jenkins-ansible* para otorgarle la propiedad del volumen a ansible (evitando así problemas de permisos con las llaves SSH).

`docker exec -it <container_id> bash`
`chown -R ansible:ansible /home/ansible`

### Plugins de Jenkins
---

Una vez desplegado Jenkins por primera vez, hay que descargar e instalar el plugin de ***Ansible***, para poder indicarle los inventarios y los playbooks de Ansible a los que llamará Jenkins. 

Por otro lado, es recomendable instalar los plugins ***AnsiColor***: esto es simplemente para darle color al Output de vuestros jobs de Jenkins como si estuviérais en la consola. Es un plugin opcional, pero os ayudará a ver vuestros output con mayor claridad y os ayudará a depurar un posible problema. Para habilitarlo, en nuestro job de Jenkins, debemos habilitar la opción dentro de *Entorno de ejecución* ***Color ANSI Console Output***. También deberemos activar, dentro de *Invoke Ansible Playbook*, en las opciones *Avanzado*, la opción ***Colorized stdout***.

### Creación de llaves SSH
---

Para crear las llaves SSH con las que trabajará Ansible, tendremos que acceder al contenedor con el usuario **ansible** y crearlas:

`docker exec -u ansible -it <container_id> bash`
`ssh-keygen -f <key_name>`

Si dejamos el directorio por defecto (/home/ansible/.ssh/), la llave se creará en el volumen que hemos al principio. Entonces, podremos copiar la llave pública en el servidor al que vayamos a acceder, en *authorized_keys*.

>Nota: Es importante recordar que, para poder conectar al servidor remoto, se necesita que exista el usuario *ansible* también en él. Una vez copiada la llave pública en *authorized_keys*, hay que darle la propiedad al usuario ansible y darle pemisos 600:

`chown ansible:ansible /home/ansible/.ssh/authorized_keys`
`chmod 600 /home/ansible/.ssh/authorized_keys` 

>Nota 2: Además, es recomendable lanzar por primera vez la conexión entre ansible y la máquina remota manualmente, para que cree el archivo *know_hosts* y las conexiones no fallen (otra opción es crear manualmente el archivo *know_hosts*). Para ello, accedemos al contenedor de *jenkins-ansible* y lanzamos un ping desde ansible con el siguiente comando:

`docker exec -it <container_id> bash`
`ansible -m ping -i <inventory_name> <host_name>`
