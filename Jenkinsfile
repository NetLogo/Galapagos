#!/usr/bin/env groovy

pipeline {

  agent any

  environment {
    JAVA_HOME="${tool 'Liberica OpenJDK 17.0.4.1'}"
    PATH="${env.JAVA_HOME}/bin:${env.PATH}"
  }

  stages {
    stage('Start') {
      steps {
        library 'netlogo-shared'
        sendNotifications('NetLogo/Galapagos', 'STARTED')
      }
    }

    stage('Build and Test') {
      steps {
        library 'netlogo-shared'
        sh 'git clean -fdx'
        sh 'git submodule deinit --force --all'
        sh 'git submodule update --init'
        sbt('scalastyle', 'sbt-1.7.1')
        sbt('coffeelint', 'sbt-1.7.1')
        sbt('test', 'sbt-1.7.1')
      }
    }

    stage('Deploy-Staging') {
      when {
        branch "master"
      }
      steps {
        library 'netlogo-shared'
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'ccl-aws-deploy', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sbt('scrapePlay', 'sbt-1.7.1')
          sh 'cp -Rv public/modelslib/ target/play-scrape/assets/'
          sh 'cp -Rv public/nt-modelslib/ target/play-scrape/assets/'
          sbt('scrapeUpload', 'sbt-1.7.1')
        }
      }
    }

    stage('Deploy') {
      when {
        branch "production"
      }
      steps {
        library 'netlogo-shared'
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'ccl-aws-deploy', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sbt('scrapePlay', 'sbt-1.7.1')
          sh 'cp -Rv public/modelslib/ target/play-scrape/assets/'
          sh 'cp -Rv public/nt-modelslib/ target/play-scrape/assets/'
          sbt('scrapeUpload', 'sbt-1.7.1')
        }
      }
    }
  }

  post {
    failure {
      library 'netlogo-shared'
      sendNotifications('NetLogo/Galapagos', 'FAILURE')
    }
    success {
      library 'netlogo-shared'
      sendNotifications('NetLogo/Galapagos', 'SUCCESS')
    }
    unstable {
      library 'netlogo-shared'
      sendNotifications('NetLogo/Galapagos', 'UNSTABLE')
    }
  }

}
