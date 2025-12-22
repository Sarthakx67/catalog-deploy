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
        stage('Plan') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh """
                        cd terraform
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=ap-south-1
                        terraform plan
                    """
                }
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
