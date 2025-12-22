pipeline {
    agent { node { label 'AGENT-1' } }
    environment{
        //here if you create any variable you will have global access, since it is environment no need of def
        packageVersion = ''
    }   
    stages {
        stage('Deploy'){
            steps{
                echo "Deploying ..."
                echo "Version from Params : ${params.version}"
            }
        }
        stage('Init'){
            steps{
                sh """
                cd terraform
                terraform init -reconfigure"""// -backend-config=${params.environment}/backend.tf -reconfigure
                //"""
            }
        }
        stage('Plan'){
            steps{
                sh """
                cd terraform
                terraform plan """// -var-file=${params.environment}/${params.environment}.tfvars -var="app_version=${params.version}" -var="env=${params.environment}"
                //"""
            }
        }
    }
    post{
        always{
            echo 'cleaning up workspace'
            //deleteDir()
            }
        }
}
