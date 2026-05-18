pipeline {
  agent { label 'python' }

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    PYTHONPATH    = "${WORKSPACE}"
    BASE_URL      = 'http://flask:5000'
    BASE_URL_MOCK = 'http://wiremock:8080'
  }

  stages {

    stage('Get Code') {
      steps {
        sh '''
          whoami
          hostname
          echo $WORKSPACE
          ls -la
        '''
        stash name: 'jmx', includes: 'test/jmeter/**'
      }
    }

    stage('Unit') {
      steps {
        sh '''
          coverage run --source=app --branch -m pytest \
            --junitxml=result-unit.xml test/unit/
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'result-unit.xml'
        }
      }
    }

    stage('Rest') {
      steps {
        sh '''
          pytest --junitxml=result-rest.xml test/rest/ || true
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'result-rest.xml'
        }
      }
    }

    stage('Static') {
      steps {
        sh '''
          flake8 --format=pylint --exit-zero --output-file=flake8.log app/
          cat flake8.log
        '''
      }
      post {
        always {
          recordIssues(
            tools: [flake8(pattern: 'flake8.log')],
            qualityGates: [
              [threshold: 8,  type: 'TOTAL', unstable: true],
              [threshold: 10, type: 'TOTAL', unstable: false]
            ]
          )
        }
      }
    }

    stage('Security Test') {
      steps {
        sh '''
          bandit --exit-zero -r app/ -f txt -o bandit.log
          cat bandit.log
        '''
      }
      post {
        always {
          recordIssues(
            tools: [pyLint(pattern: 'bandit.log')],
            qualityGates: [
              [threshold: 2, type: 'TOTAL', unstable: true],
              [threshold: 4, type: 'TOTAL', unstable: false]
            ]
          )
        }
      }
    }

    stage('Performance') {
      agent { label 'jmeter' }
      steps {
        unstash 'jmx'
        sh '''
          whoami
          hostname
          jmeter -n -t test/jmeter/flask.jmx -l perf-result.jtl \
            -Jhost=flask -Jport=5000
        '''
        perfReport sourceDataFiles: 'perf-result.jtl'
      }
    }

    stage('Coverage') {
      steps {
        sh '''
          coverage xml -o coverage.xml
          coverage report
        '''
      }
      post {
        always {
          recordCoverage(
            tools: [[parser: 'COBERTURA', pattern: 'coverage.xml']],
            qualityGates: [
              [metric: 'LINE',   baseline: 'PROJECT', threshold: 85.0, criticality: 'FAILURE'],
              [metric: 'LINE',   baseline: 'PROJECT', threshold: 95.0, criticality: 'UNSTABLE'],
              [metric: 'BRANCH', baseline: 'PROJECT', threshold: 80.0, criticality: 'FAILURE'],
              [metric: 'BRANCH', baseline: 'PROJECT', threshold: 90.0, criticality: 'UNSTABLE']
            ]
          )
        }
      }
    }

  }

  post {
    always {
      cleanWs()
    }
  }
}
