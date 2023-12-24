pipeline {
    agent any

    environment {
        DOCKER_HUB_PASSWORD = credentials('Dockerhub_pass')
        BUILD_TAG = "${BUILD_NUMBER}"
        // These variables are for terraform to connect to Azure account
        ARM_SUBSCRIPTION_ID = credentials('ARM_SUBSCRIPTION_ID')
        ARM_CLIENT_ID = credentials('ARM_CLIENT_ID')
        ARM_CLIENT_SECRET = credentials('ARM_CLIENT_SECRET') 
        ARM_TENANT_ID = credentials('ARM_TENANT_ID')

    }

    stages {
        stage('Checkout') {
            steps {
                // Check out your source code from your version control system, e.g., Git.
                sh 'rm -rf devsecops-project'
                sh 'git clone https://github.com/khalilsellamii/devsecops-project'
            }
        }
          
        stage('golang_unit_testing') {
            steps {
                script{
                    try {
                        sh '/root/go/bin/gosec ./...'
                    }  catch (Exception e) {
                        echo "Gosec test failed, but continuing the pipeline..."
                    }
                }
            }
        }

        stage('mysql-db-connection-test') {
            steps {
                script {
                    try {
                         sh 'cd src/ && go test' 
                    } catch (Exception e) {
                        echo "Error connecting to the database at this url, but continuing the pipeline..."
                    }
                }               
            }
        }

        stage('sonarqube_scanner') {
            steps {
                sh '''
                    /opt/sonar-scanner-4.6.2.2472-linux/bin/sonar-scanner --version
                    /opt/sonar-scanner-4.6.2.2472-linux/bin/sonar-scanner -Dsonar.projectKey=projet-devops -Dsonar.sources=. -Dsonar.host.url=http://sonarqube-server:9999 -Dsonar.token=sqp_c8c0f860890b074339b03a624b4aa157b0e19211
                '''
            }
        }   

        stage('Build Docker Image') {
            steps {
                // Build your Docker image. Make sure to specify your Dockerfile and any other build options.
                sh 'docker build -t khalilsellamii/projet-devops:v0.test .'
            }
        }

        stage('Trivy Scan Docker Image') {
            steps {
                script {
                    try {
                // Build your Docker image. Make sure to specify your Dockerfile and any other build options.
                sh 'touch trivy_scan_results && trivy image khalilsellamii/projet-devops:v0.test --format json --output ./trivy_scan_results '
                    } catch (Exception e) {
                        echo "Trivy docker scan of the recently built image found some security issues with the image, consider fixing them before pushing it to docker_hub, but continuing building the pipeline anyway ... :)"
                    }
                }
            }
        }        

        stage('Push to Docker Hub') {
            steps {
                // Log in to Docker Hub using your credentials
                sh 'docker login -u khalilsellamii -p $DOCKER_HUB_PASSWORD'

                // Push the built image to Docker Hub
                sh 'docker push khalilsellamii/projet-devops:v0.test'
            }
        }

        stage('Docker Bench Scan Docker environment') {
            steps {
                script {
                    try {
                         sh '''
                             
                            rm -rf docker-bench-security
                            git clone https://github.com/docker/docker-bench-security.git
                            cd docker-bench-security/
                            chmod +x docker-bench-security.sh  
                            touch docker_bench_security_scan_results
                            ./docker-bench-security.sh > docker_bench_security_scan_results
                            cat docker_bench_security_scan_results  
         
                         '''                        
                    } catch (Exception e) {
                        echo "The docker bench security testing scan found some severe vulnerabilities on the host system, but continuing building the pipeline anyway ... :)"
                    }
                }
            }
        }           

        stage('Provision AKS cluster with TF') {
            steps {
                script {

                    sh '''
                       
                       cd terraform/
    
                       terraform fmt && terraform init
    
                       terraform plan && terraform apply --auto-approve 
    
                       terraform output kube_config > kubeconfig && cat kubeconfig 

                       sed -i '1d;$d' kubeconfig && cat kubeconfig
    
                       cd ../
                    '''

                }
            }
        }

        stage('Deploy on AKS') {
            steps {

                sh '''
                    pwd && ls ./terraform
                    export KUBECONFIG=/var/jenkins_home/workspace/projet-devops/terraform/kubeconfig
                    cd kubernetes/
                    sleep 5
                    kubectl apply -f db-configmap.yaml
                    kubectl apply -f db-pass-secret.yaml
                    kubectl apply -f mysql-stfulset.yaml
                    sleep 10
                    kubectl apply -f mysql-svc.yaml
                    kubectl apply -f my-golang-app-deployment.yaml
                    sleep 10
                    kubectl apply -f golang-svc.yaml

                    sleep 15

                    kubectl get all,pv,pvc,storageClass,secret,cm

                '''
            }
        }   

        stage('Helm & Cert-manager & Nginx-Ingress') {
            steps {
                script {
                    try {
                        sh '''

                        export KUBECONFIG=/var/jenkins_home/workspace/projet-devops/terraform/kubeconfig

                        helm repo add jetstack https://charts.jetstack.io
                        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                        helm repo update
                        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
                        helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.1
                        helm install app-ingress ingress-nginx/ingress-nginx --namespace ingress --create-namespace --set controller.replicaCount=2 --set controller.nodeSelector."kubernetes\\.io/os"=linux --set defaultBackend.nodeSelector."kubernetes\\.io/os"=linux

                        kubectl apply -f cert-manager-tls/issuer.yaml
                        kubectl apply -f cert-manager-tls/certificate.yaml


                    '''
                    } catch (Exception e) {
                        echo "the helm packages that you are trying to install are already installed with the same name"
                    }
                }
            }
        }


        stage('Monitoring Prometheus & Grafana') {
            steps {
                script {
                    try {

                    sh '''

                        export KUBECONFIG=/var/jenkins_home/workspace/projet-devops/terraform/kubeconfig
                        kubectl create ns monitoring 
                        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                        helm repo update
                        helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
                        kubectl get all,secret,configMap --namespace monitoring           

                    '''


            
                    } catch (Exception e) {
                        echo "the prometheus operator monitoring stack is already installed with the same name "
                    }
                }
            }
        }  

        stage('Add custom alerting rule') {
            steps {
                sh '''
                    export KUBECONFIG=/var/jenkins_home/workspace/projet-devops/terraform/kubeconfig
                    kubectl apply -f ./monitoring/alert-rule.yaml --namespace monitoring
                    
                    sleep 25

                    kubectl apply -f ./monitoring/email-secret.yaml --namespace monitoring
                    kubectl apply -f ./monitoring/alert-manager-config.yaml --namespace monitoring
                    
                    chmod +x monitoring/stress-script.sh
                '''
            }
        }                 

    }
    post {
        success {
            echo ' Pipeline completed successfully! :)) '
            echo ' Now, The Golang application is successfully deployed on the AKS cluster :)) '
            echo ' Visit th public DNS:  https://khalil-projet-devops.20.74.61.124.nip.io to access the application :) '
        }
    }

}