# Docker on Windows 10 for work with Hashistack and AWS

This docker container is used for provisioning clusters in AWS using terraform and ansible. It uses repository `git@github.com:markokole/aws-consul-terraform.git` for provisioning HDP clusters in AWS.

Latest version of Centos is used to create this container.
In the container, awscli, ansible, terraform and consul are installed, consul local server is started and git2consul service is started to fetch configuration from another git repository.

1. Start Docker in Windows.
2. Open PowerShell.
3. Step into `docker-on-wins-hashistack` folder.
4. Create a file `aws_cred.env` and put `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in them. Use `key=value` format. This file is used in the `docker build` line.
5. Create a file `id_rsa` and add the private key to connect to the EC2 instances in AWS. This file is copied to the container in DockerFile.
6. File `copy_files/encrypt_consul.json` holds a 16-bytes, Base64 encoded key for encrypting traffic between consul servers and agents.
7. Create image by running `docker build . --tag=aws-terraform-image`.
8. Create container based on the image `docker run -itd --rm -p8501:8500 --name aws-terraform --hostname terraformer -v C:\marko\GitHub\aws-consul-terraform:/local-git --env-file "env.list" --env-file "aws_cred.env" aws-terraform-image`.
Option `-v` maps the github repository on Windows drive to a folder in the container.
Port `8501` is opened so that the Consul web UI can be reached from a web browser in Windows.
9. Start container `docker exec -it aws-terraform bash`.

Once in the container:
(This is not best practice but a temporary solution)
1. Run `ps aux | grep consul` to see if services `consul` and `git2consul` are running.
2. type `terraform` to see if terraform is installed.

If container should be recreated based on an updated image, stop the container by running `docker stop aws-terraform`. Now the new container, with the same name, can be created.
