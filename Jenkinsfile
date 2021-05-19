#!/usr/bin/env groovy

pipeline {

  agent any

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
        sh 'git submodule foreach git reset --hard'
        sh 'git submodule foreach git clean -xdf'
        sh 'git submodule update --init'
        sbt('scalastyle', 'sbt-1.1.1')
        sh 'yarn install'
        sh 'yarn coffeelint'
        sbt('test', 'sbt-1.1.1')
      }
    }

    stage('Deploy-Staging') {
      when {
        branch "master"
      }
      steps {
        library 'netlogo-shared'
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'ccl-aws-deploy', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sbt('scrapePlay', 'sbt-1.1.1')
          sh 'cp -Rv public/modelslib/ target/play-scrape/assets/'
          sh 'cp -Rv public/nt-modelslib/ target/play-scrape/assets/'
          sbt('scrapeUpload', 'sbt-1.1.1')
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
          sbt('scrapePlay', 'sbt-1.1.1')
          sh 'cp -Rv public/modelslib/ target/play-scrape/assets/'
          sh 'cp -Rv public/nt-modelslib/ target/play-scrape/assets/'
          sbt('scrapeUpload', 'sbt-1.1.1')
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
