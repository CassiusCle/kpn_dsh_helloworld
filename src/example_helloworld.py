from confluent_kafka import Producer, Consumer
import os
import signal
import json
import sys
import logging
import datetime

# Set up logging
logger = logging.getLogger('kafka_feed')
# Set logging level
loglevel = "DEBUG"
logger.setLevel(loglevel)
logger.addHandler(logging.StreamHandler(sys.stdout))

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
        produce_message()
        consumer = create_consumer()
        consumer.subscribe([TOPIC])
        
        while True:
                msg = consumer.poll(1000) # start consuming

                if msg is not None:
                        # print messages
                        print('Received message:{}'.format(msg.value().decode('utf-8')))
                        produce_message()
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
        
def create_producer():
        return Producer({
                'bootstrap.servers' : ','.join(TENANT_CONFIG['brokers']),
                'group.id' :TENANT_CONFIG['shared_consumer_groups'][0],
                'client.id' :CLIENT_ID,
                'security.protocol' : 'ssl',
                'ssl.key.location' : PKI_KEY,
                'ssl.certificate.location' : PKI_CERT,
                'ssl.ca.location' :  PKI_CACERT
        })

def delivery_report(err, msg):
    """ Called once for each message produced to indicate delivery result.
        Triggered by poll() or flush(). """
    if err is not None:
        logger.warning(f'Message delivery failed: {err} \n \n')
    else:
        logger.debug(f'Message delivered to {msg.topic()} [{msg.partition()}] \n \n')
           
def produce_message():
        producer = create_producer() 
        producer.poll(0)
        now = datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S")
        producer.produce( topic = TOPIC, value = f"{{{now}: Hello world!}}", callback = delivery_report )
        producer.flush()

# Sigterm
signal.signal(signal.SIGTERM, handle_sigterm)
        
# Start
if __name__ == '__main__':

    wait_for_message()
