Got it! Here’s the updated guide for Ansible Automation Platform (AAP) v2.5 with custom SSL certificates in a 6-node HA deployment.

Install Ansible Automation Platform v2.5 with Custom Certificates (6-Node HA Setup)

1. Node Architecture
	•	2 Gateway VMs → (Automation Gateway for event-driven automation)
	•	2 Controller VMs → (Hybrid: Controller + Execution nodes for HA)
	•	1 EDA Controller VM → (For event-driven automation)
	•	1 Automation Hub VM → (Stores and distributes collections)

2. Pre-Installation Requirements

System Requirements

Component	CPU	RAM	Storage
Controller (HA)	4+ vCPUs	16GB+	50GB+
Execution Nodes	4+ vCPUs	8GB+	30GB+
Automation Hub	4 vCPUs	8GB+	50GB+
Gateway Nodes	4 vCPUs	8GB+	30GB+
EDA Controller	4 vCPUs	8GB+	30GB+

Prepare Custom SSL Certificates
	•	Obtain CA-signed certificates (.crt, .key, .pem)
	•	Place them on each node:

/etc/pki/tls/certs/  # For SSL Certificates
/etc/pki/tls/private/  # For Private Keys


	•	Set Correct Permissions:

chmod 600 /etc/pki/tls/private/*.key
chmod 644 /etc/pki/tls/certs/*.crt

3. Install AAP v2.5 Installer

On the Primary Controller Node

subscription-manager register
subscription-manager attach --auto
subscription-manager repos --enable ansible-automation-platform-2.5-for-rhel-8-x86_64-rpms
yum install -y ansible-automation-platform-installer

Download and Extract the Installer

cd /opt/
git clone https://github.com/ansible/automation-controller-installer.git
cd automation-controller-installer

4. Configure the Inventory File

Edit /opt/automation-controller-installer/inventory:

[automationcontroller]
controller-1 ansible_host=192.168.1.10
controller-2 ansible_host=192.168.1.11

[execution_nodes]
controller-1
controller-2

[automationhub]
hub-1 ansible_host=192.168.1.40

[eda_controller]
eda-1 ansible_host=192.168.1.50

[automation-gateway]
gateway-1 ansible_host=192.168.1.60
gateway-2 ansible_host=192.168.1.61

[all:vars]
admin_password='YourSecurePassword'

pg_host='192.168.1.30'
pg_port='5432'
pg_database='awx'
pg_username='awx'
pg_password='YourSecureDBPassword'

registry_url='registry.redhat.io'

# SSL Certificate Paths
automationcontroller_ssl_cert=/etc/pki/tls/certs/automationcontroller.crt
automationcontroller_ssl_key=/etc/pki/tls/private/automationcontroller.key
automationcontroller_ssl_ca=/etc/pki/tls/certs/ca-bundle.crt

automationhub_ssl_cert=/etc/pki/tls/certs/automationhub.crt
automationhub_ssl_key=/etc/pki/tls/private/automationhub.key
automationhub_ssl_ca=/etc/pki/tls/certs/ca-bundle.crt

eda_controller_ssl_cert=/etc/pki/tls/certs/eda.crt
eda_controller_ssl_key=/etc/pki/tls/private/eda.key
eda_controller_ssl_ca=/etc/pki/tls/certs/ca-bundle.crt

automation_gateway_ssl_cert=/etc/pki/tls/certs/gateway.crt
automation_gateway_ssl_key=/etc/pki/tls/private/gateway.key
automation_gateway_ssl_ca=/etc/pki/tls/certs/ca-bundle.crt

5. Run the Installation

Execute:

./setup.sh

This installs:
	•	2 HA Controllers (Hybrid Execution Nodes)
	•	1 Automation Hub
	•	2 Gateway Nodes
	•	1 EDA Controller
	•	Custom SSL Certificates

6. Post-Installation Verification

Check Services on Each Node

sudo systemctl status automation-controller.service
sudo systemctl status automation-hub.service
sudo systemctl status receptor.service
sudo systemctl status automation-gateway.service
sudo systemctl status eda-controller.service

Verify SSL Certificates

openssl x509 -in /etc/pki/tls/certs/automationcontroller.crt -text -noout
openssl x509 -in /etc/pki/tls/certs/automationhub.crt -text -noout

Test Web UI
	•	Automation Controller: https://controller-1.example.com
	•	Automation Hub: https://hub-1.example.com
	•	EDA Controller: https://eda-1.example.com

7. Enable Services on Boot

sudo systemctl enable automation-controller.service
sudo systemctl enable automation-hub.service
sudo systemctl enable receptor.service
sudo systemctl enable automation-gateway.service
sudo systemctl enable eda-controller.service

Verify HA Cluster

awx-manage list_instances

8. Troubleshooting

Check Logs

journalctl -u automation-controller -n 50 --no-pager
journalctl -u automation-hub -n 50 --no-pager
journalctl -u automation-gateway -n 50 --no-pager

Verify Database Connection

psql -h 192.168.1.30 -U awx -d awx -c "SELECT * FROM public.main_instance;"

Conclusion

This guide installs Ansible Automation Platform v2.5 in an HA architecture with custom SSL certificates ensuring a secure and scalable deployment.

Would you like additional configurations such as LDAP authentication, RBAC settings, or performance tuning?