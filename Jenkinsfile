node('common')  {
	PROJECT_NAME = 'media-gateway'
	AWS_ACCOUNT_NUMBER = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/AWS_ACCOUNT_NUMBER?raw", returnStdout: true).trim()
	FQDN = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/FQDN?raw", returnStdout: true).trim()
	FQDN_HYPHENATED = FQDN.replace('.', '-')
	ENVIRONMENT = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/ENVIRONMENT?raw", returnStdout: true).trim()
	PLATFORM = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/PLATFORM?raw", returnStdout: true).trim()
	PLATFORM_LOWERCASE = PLATFORM.toLowerCase()
	BRANCH = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/branch?raw", returnStdout: true).trim()
	REGION = sh(script: "curl http://consul:8500/v1/kv/${PROJECT_NAME}/config/REGION?raw", returnStdout: true).trim()

  try {
    stage('Code Checkout') {
      git branch: "${BRANCH}", // <- this needs to be solved
      url: "git@github.com:reachlocal/${PROJECT_NAME}.git"
    }

    stage('Test') {
      sh 'pwd'
      sh './gradlew clean'
      sh './gradlew test'
    }

    stage('Build') {
      sh './gradlew build'
			stash includes: 'Dockerfile', name: 'dockerfile'
			stash includes: 'build/libs/media-gateway-0.0.1-SNAPSHOT.jar', name: 'jar'
    }
  }

  catch (err) {
    currentBuild.result = "FAILURE"
	throw err
	}
}

node('docker-builds') {

  stage('Config') {
		echo "configuring..."
		sh "Job='media-gateway' /var/jenkins_home/jenkins-rl-bin/properties_parser/main.py ${REGION} ${ENVIRONMENT}-${PLATFORM_LOWERCASE}"
		stash includes: 'application.properties' , name: 'application-properties'
  }

  stage('Docker Build') {
		unstash 'dockerfile'
		unstash 'jar'
		sh 'if [ -d newrelic ]; then echo "newrelic directory already exists"; else mkdir newrelic; fi'
		sh 'aws s3 cp s3://jenkins-master-artifact-repository/thirdparty_software/newrelic/newrelic.jar ./newrelic/'
		sh 'aws s3 cp s3://jenkins-master-artifact-repository/thirdparty_software/newrelic/newrelic.yml ./newrelic/'
		sh 'sed -i \'s/^  app_name: My Application$/  app_name: media-gateway/\' newrelic/newrelic.yml'
    sh "docker build -t ${PROJECT_NAME}:${BRANCH} --build-arg APP_PROPERTIES=\"./application.properties\" --build-arg NEWRELIC=\"./newrelic\" ."
    sh "docker tag ${PROJECT_NAME}:${BRANCH} ${AWS_ACCOUNT_NUMBER}.dkr.ecr.us-west-2.amazonaws.com/${PROJECT_NAME}-${FQDN_HYPHENATED}:${BRANCH}"
  }

  stage('Docker Deploy') {
    AWS_LOGIN = sh(script: "aws ecr get-login --region ${REGION} --profile ${ENVIRONMENT}-${PLATFORM_LOWERCASE} --no-include-email", returnStdout: true).trim()
    sh(script: "echo $AWS_LOGIN |/bin/bash -; docker push ${AWS_ACCOUNT_NUMBER}.dkr.ecr.us-west-2.amazonaws.com/${PROJECT_NAME}-${FQDN_HYPHENATED}:${BRANCH}", returnStdout: true)
  }
}

// groovy ONLY executes on master nodes and must be included in scriptApproval.xml
// README: https://github.com/jenkinsci/pipeline-plugin/blob/master/TUTORIAL.md#serializing-local-variables
import groovy.text.StreamingTemplateEngine

@NonCPS
def sortBindings(vars) {
  def template = new StreamingTemplateEngine().createTemplate(text);
  String stuff = template.make(vars);
	return stuff;
}
