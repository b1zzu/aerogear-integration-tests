
node('psi_rhel8') {
  cleanWs()

  try {
    sh 'docker network create aerogear'

    stage("checkout") {
      checkout scm
    }

    withCredentials([
      usernamePassword(
        credentialsId: 'browserstack',
        usernameVariable: 'BROWSERSTACK_USER',
        passwordVariable: 'BROWSERSTACK_KEY'
      ),
      string(credentialsId: 'firebase-server-key', variable: 'FIREBASE_SERVER_KEY'),
      string(credentialsId: 'firebase-sender-id', variable: 'FIREBASE_SENDER_ID'),
      file(credentialsId: 'google-services', variable: 'GOOGLE_SERVICES'),
    ]) {
      stage('build testing app') {
        parallel 
          Android: {
            docker.image('circleci/android:api-28-node').inside('-u root:root') {
                sh 'apt install gradle'
                sh 'npm -g install cordova@8'
                sh 'cp ${GOOGLE_SERVICES} ./fixtures/google-services.json'
                dir('app') {
                  sh 'npm install'
                  sh 'npm build:android'
                }
                // androidAppUrl = sh(returnStdout: true, script: 'cat "./testing-app/bs-app-url.txt" | cut -d \'"\' -f 4').trim()
            }
          }
          iOS: {
            // node('osx5x') {
            //   cleanWs()

            //   withEnv([
            //     'DEVELOPMENT_TEAM=GHPBX39444',
            //     'KEYCHAIN_PASS=5sdfDSO8ig'
            //   ]) {
            //     sh 'npm -g install cordova@8'
            //     sh 'security unlock-keychain -p $KEYCHAIN_PASS'
            //     dir('app') {
            //       sh 'npm install'
            //       sh 'npm build:android'
            //     }
            //   }
            // }
          }
      }
      
      stage('test') {
        try {
          sh 'sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose'
          sh 'sudo chmod +x /usr/local/bin/docker-compose'
          sh 'docker-compose up -d'
          docker.image('circleci/node:dubnium-stretch').inside('-u root:root --network aerogear') {
            sh 'npm install'
            withEnv([
              'BROWSERSTACK_APP=' + androidAppUrl
            ]) {
              sh 'npm start -- test/**/*.js'
            }
          }
        } catch (e) {
          throw e
        } finally {
          sh 'docker-compose down'
        }
      }
        
    }
  } catch (e) {
    throw e
  } finally {
    sh 'docker network rm aerogear || true'
  }
}