
# Troubleshooting Guide: LKE VLAN Automation

This document provides step-by-step troubleshooting steps for common issues observed with the LKE VLAN Automation DaemonSet and ConfigMap synchronization.

---

## 🛠️ **Issue 1:** SSH Key Not Propagated to `/root/.ssh/authorized_keys`
**Symptoms:**  
- When you `kubectl exec` into the `root-ssh-manager-*` pods, the `.ssh` directory is missing or `/host-root/root/.ssh/authorized_keys` is empty.

**Solution:**  
1. Verify the `ConfigMap` contents:
    ```bash
    kubectl describe configmap root-ssh-pubkeys -n kube-system
    ```

2. You should see your SSH key listed under `mykey1`. If not, re-apply the `pub-keys.yaml`:
    ```bash
    kubectl apply -f pub-keys.yaml
    ```

3. Check if the `DaemonSet` is running:
    ```bash
    kubectl get daemonset root-ssh-manager -n kube-system
    ```

4. If the DaemonSet is not updating, restart it:
    ```bash
    kubectl rollout restart daemonset/root-ssh-manager -n kube-system
    ```

5. Verify the key inside the pod:
    ```bash
    kubectl exec -it root-ssh-manager-xxxxx -n kube-system -- cat /host-root/root/.ssh/authorized_keys
    ```
    Replace `xxxxx` with the actual pod name.

---

## 🛠️ **Issue 2:** `/host-root/root/.ssh` Directory is Missing
**Symptoms:**  
- When you `kubectl exec` into the pod and navigate to `/host-root/root/`, there is no `.ssh` directory.

**Solution:**  
1. Manually verify inside the pod:
    ```bash
    kubectl exec -it root-ssh-manager-xxxxx -n kube-system -- /bin/sh
    ```
    Inside the shell:
    ```sh
    mkdir -p /host-root/root/.ssh
    ```

2. Restart the DaemonSet:
    ```bash
    kubectl rollout restart daemonset/root-ssh-manager -n kube-system
    ```

---

## 🛠️ **Issue 3:** `/pubkeys/authorized_keys` is Empty Inside the Pod
**Symptoms:**  
- When running:
    ```bash
    ls /pubkeys
    ```
    It shows `mykey1` instead of `authorized_keys`.

**Solution:**  
1. Update the `DaemonSet` script to read from the correct path:  
    In `pub-keys-to-node-daemonset.yaml`, change:
    ```sh
    cat /pubkeys/mykey1 > /host-root/root/.ssh/authorized_keys
    ```

2. Re-apply the DaemonSet:
    ```bash
    kubectl apply -f pub-keys-to-node-daemonset.yaml
    ```

3. Restart the DaemonSet to propagate changes:
    ```bash
    kubectl rollout restart daemonset/root-ssh-manager -n kube-system
    ```

---

## 🛠️ **Issue 4:** DaemonSet Not Syncing on `ConfigMap` Changes
**Symptoms:**  
- Updating the `ConfigMap` does not reflect in the `/pubkeys/mykey1`.

**Solution:**  
1. Manually delete the old ConfigMap:
    ```bash
    kubectl delete configmap root-ssh-pubkeys -n kube-system
    ```

2. Re-apply the updated ConfigMap:
    ```bash
    kubectl apply -f pub-keys.yaml
    ```

3. Restart the DaemonSet:
    ```bash
    kubectl rollout restart daemonset/root-ssh-manager -n kube-system
    ```

---

## 🛡️ **Future Improvements:**  
We can enhance the DaemonSet to automatically refresh the keys if the `ConfigMap` is updated. This can be achieved using an `inotify` watch inside the container.

---

## 📌 **Support:**  
If issues persist, please contact the infrastructure automation team for further support.
