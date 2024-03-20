# Services logs locations and pod descriptions for VMware Aria Automation and Automation Orchestrator 8.x
# https://kb.vmware.com/s/article/95224
kubectl get pods -n prelude

ls -l /services-logs/prelude/codestream-app/file-logs/codestream-app
cat /services-logs/prelude/codestream-app/file-logs/codestream-app.log

cat /services-logs/prelude/codestream-app/file-logs/codestream-app.log | grep -i 4ec3f6b4-7843-4ee0-9c12-bad9fc3bad35

tail -f /services-logs/prelude/codestream-app/file-logs/codestream-app.log | grep -i 4ec3f6b4-7843-4ee0-9c12-bad9fc3bad35
