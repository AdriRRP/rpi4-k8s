WORKING_DIR=backup_`date +%Y%m%d`

mkdir -p $WORKING_DIR

# Foreach namespace
for ns in `kubectl get ns -o name | sed 's#namespace/##g'`
do
    # Current directory
    DIR=$WORKING_DIR/$ns
    mkdir -p $DIR

    # Dump namespace
    kubectl get ns airflow -o yaml > $DIR/${ns}_ns.yaml

    # Dump pods (in subfolder)
    mkdir -p $DIR/pods/
    for pod in `kubectl -n $ns get pods -o name | sed 's#pod/##g'`
    do
        kubectl -n $ns get pod $pod -o yaml > $DIR/pods/$pod.yaml
    done

    # Dump replica sets (in subfolder)
    mkdir -p $DIR/rs/
    for rs in `kubectl -n $ns get rs -o name | sed 's#replicaset.apps/##g'`
    do
        kubectl -n $ns get rs $rs -o yaml > $DIR/rs/replicaset_$rs.yaml
    done

    # Dump deployments
    for dpl in `kubectl -n $ns get deployments -o name | sed 's#deployment.apps/##g'`
    do
        kubectl -n $ns get deployment $dpl -o yaml > $DIR/deployment_$dpl.yaml
    done

    # Dump deployments
    for ds in `kubectl -n $ns get ds -o name | sed 's#daemonset.apps/##g'`
    do
        kubectl -n $ns get ds $ds -o yaml > $DIR/daemonset_$ds.yaml
    done

    # Dump statefulsets
    for sts in `kubectl -n $ns get sts -o name | sed 's#statefulset.apps/##g'`
    do
        kubectl -n $ns get sts $sts -o yaml > $DIR/statefulset_$sts.yaml
    done

    # Dump jobs
    for job in `kubectl -n $ns get jobs -o name | sed 's#job.batch/##g'`
    do
        kubectl -n $ns get job $job -o yaml > $DIR/job_$job.yaml
    done

    # Dump cron jobs
    for cjob in `kubectl -n $ns get cronjobs -o name | sed 's#cronjob.batch/##g'`
    do
        kubectl -n $ns get cronjob $cjob -o yaml > $DIR/cronjob_$cjob.yaml
    done

    # Dump configmaps
    for cm in `kubectl -n $ns get cm -o name | sed 's#configmap/##g'`
    do
        kubectl -n $ns get cm $cm -o yaml > $DIR/configmap_$cm.yaml
    done

    # Dump secrets
    for secret in `kubectl -n $ns get secrets -o name | sed 's#secret/##g'`
    do
        kubectl -n $ns get secret $secret -o yaml > $DIR/secret_$secret.yaml
    done

    # Dump poddisruptionbudgets
    for pdb in `kubectl -n $ns get poddisruptionbudgets -o name | sed 's#poddisruptionbudget.policy/##g'`
    do
        kubectl -n $ns get poddisruptionbudget $pdb -o yaml > $DIR/poddisruptionbudget_$pdb.yaml
    done

    # Dump services
    for svc in `kubectl -n $ns get svc -o name | sed 's#service/##g'`
    do
        kubectl -n $ns get svc $svc -o yaml > $DIR/service_$svc.yaml
    done

    # Dump endpoints
    for ep in `kubectl -n $ns get ep -o name | sed 's#endpoints/##g'`
    do
        kubectl -n $ns get ep $ep -o yaml > $DIR/endpoint_$ep.yaml
    done

    # Dump persitent volumes
    for pv in `kubectl -n $ns get pv -o name | sed 's#persistentvolume/##g'`
    do
        kubectl -n $ns get pv $pv -o yaml > $DIR/pv_$pv.yaml
    done

    # Dump persitent volumes claims
    for pvc in `kubectl -n $ns get pvc -o name | sed 's#persistentvolumeclaim/##g'`
    do
        kubectl -n $ns get pvc $pvc -o yaml > $DIR/pvc_$pvc.yaml
    done

    # Dump service accounts
    for sa in `kubectl -n $ns get sa -o name | sed 's#serviceaccount/##g'`
    do
        kubectl -n $ns get sa $sa -o yaml > $DIR/sa_$sa.yaml
    done

    # Dump roles
    for role in `kubectl -n $ns get role -o name | sed 's#role.rbac.authorization.k8s.io/##g'`
    do
        kubectl -n $ns get role $role -o yaml > $DIR/role_$role.yaml
    done

    # Dump roles bindings
    for rb in `kubectl -n $ns get rolebinding -o name | sed 's#rolebinding.rbac.authorization.k8s.io/##g'`
    do
        kubectl -n $ns get rolebinding $rb -o yaml > $DIR/rolebinding_$rb.yaml
    done
done

# Dump priorityclasses
for pc in `kubectl get priorityclasses -o name | sed 's#priorityclass.scheduling.k8s.io/##g'`
do
    kubectl get priorityclass $pc -o yaml > $WORKING_DIR/priorityclass_$pc.yaml
done

# Dump storage classes
for sc in `kubectl get storageclass -o name | sed 's#storageclass.storage.k8s.io/##g'`
do
    kubectl get storageclass $sc -o yaml > $WORKING_DIR/storageclass_$sc.yaml
done

# Dump cluster roles
for cr in `kubectl get clusterrole -o name | sed 's#clusterrole.rbac.authorization.k8s.io/##g'`
do
    kubectl get clusterrole $cr -o yaml > $WORKING_DIR/clusterrole_$cr.yaml
done

# Dump cluster roles bingings
for crb in `kubectl get clusterrolebinding -o name | sed 's#clusterrolebinding.rbac.authorization.k8s.io/##g'`
do
    kubectl get clusterrolebinding $crb -o yaml > $WORKING_DIR/clusterrolebinding_$crb.yaml
done

# Dump security policies
for psp in `kubectl get podsecuritypolicies -o name | sed 's#podsecuritypolicy.policy/##g'`
do
    kubectl get podsecuritypolicy $psp -o yaml > $WORKING_DIR/podsecuritypolicy_$psp.yaml
done
