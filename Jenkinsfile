pipeline {
agent any

parameters {
    choice(
        name: 'ENV',
        choices: ['dev', 'uat', 'prod'],
        description: 'Select Environment'
    )
    choice(
        name: 'ACTION',
        choices: ['plan', 'apply', 'destroy'],
        description: 'Select Terraform Action'
    )
    string(
        name: 'BRANCH',
        defaultValue: 'main',
        description: 'Git branch'
    )
}

stages {

    stage('Checkout') {
        steps {
            checkout scmGit(
                branches: [[name: "*/${params.BRANCH}"]],
                userRemoteConfigs: [[url: 'https://github.com/ygminds73/terraform-root.git']]
            )
        }
    }

    stage('Terraform Init') {
        steps {
            sh """
            terraform init -reconfigure \
            -backend-config="key=${params.ENV}/terraform.tfstate"
            """
        }
    }

    stage('Terraform Action') {
        steps {
            script {
                def tfvarsFile = "envs/${params.ENV}.tfvars"

                if (params.ACTION == 'plan') {
                    echo "Running PLAN for ${params.ENV}"
                    sh "terraform plan -var-file=${tfvarsFile}"
                } 
                else if (params.ACTION == 'apply') {
                    echo "Running APPLY for ${params.ENV}"
                    sh "terraform apply -auto-approve -var-file=${tfvarsFile}"
                } 
                else if (params.ACTION == 'destroy') {
                    echo "Running DESTROY for ${params.ENV}"
                    sh "terraform destroy -auto-approve -var-file=${tfvarsFile}"
                }
            }
        }
    }
}

}
