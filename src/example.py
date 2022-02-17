from confluent_kafka import Producer, Consumer
import os
import signal
import json
import sys

# Config
TENANT_CONFIG = json.loads(os.environ['JSON_TENANT_CONFIG'])
TENANT_NAME = os.environ['TENANT_NAME']
PKI_CACERT = os.environ['DSH_PKI_CACERT']
PKI_KEY = os.environ['DSH_PKI_KEY']
PKI_CERT = os.environ['DSH_PKI_CERT']
TOPIC = os.environ['STREAM']
CLIENT_ID=os.environ['MESOS_TASK_ID']

# Print config
print(json.dumps(TENANT_CONFIG, indent=4, sort_keys=True))

# Functions
def wait_for_message():

        consumer = create_consumer()
        consumer.subscribe([TOPIC])
        while True:
                msg = consumer.poll(1.0) # start consuming

                if msg is not None:
                        # print messages
                        print('Received message:{}'.format(msg.value().decode('utf-8')))
                else:
                        continue


def create_consumer():
        return Consumer({
                'bootstrap.servers' : ','.join(TENANT_CONFIG['brokers']),
                'group.id' :TENANT_CONFIG['shared_consumer_groups'][0],
                'client.id' :CLIENT_ID,
                'security.protocol' : 'ssl',
                'ssl.key.location' : PKI_KEY,
                'ssl.certificate.location' : PKI_CERT,
                'ssl.ca.location' :  PKI_CACERT
        })

def handle_sigterm(signum, frame):
        print('Receiving sigterm')
        sys.exit(1)

# Sigterm
signal.signal(signal.SIGTERM, handle_sigterm)
        
# Start
if __name__ == '__main__':
    wait_for_message()
