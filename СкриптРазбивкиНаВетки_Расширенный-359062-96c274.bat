
#!/bin/bash

# --��������� �������.������--
prefix="Task-" # ������� ��� ������ ������ � �������
DebugMode=False # ����� ������� ������� � ������� ��������� ��� �������� � ���� �����. ���� �� True, �� ������ �����.
# --��������� �������.�����--

git pull
git checkout -B "storage_1c" "origin/storage_1c"
git pull
git checkout -B "branch_sync_hran" "origin/branch_sync_hran"
# �������� ���� �� branch_sync_hran �� master, ������� ���������� ��� ��������� ������ � ���� 1� ����� gitsync.
logof=$(git log --reverse storage_1c...branch_sync_hran --pretty=format:"%h;%s|" | tr -d '\r\n') 
echo "����� ����: $logof"
# ��������� � ������ my_array ��� �������� � ����� ���������� ��������.
IFS='|' read -ra my_array <<< "$logof"
for i in "${my_array[@]}"
    do
        echo "---����: $i"
        commit=($(echo $i | sed 's/;.*//'))
        committext=$(git show -s --format=%s $commit)
        echo "����� ������ �������: $committext"
        # ������� � ci � skip ��������� �� �������� � ���� �����
        if [[ "$i" =~ "ci:" ]] || [[ "$i" =~ "skip" ]] || [[ "$i" =~ "Update .gitlab-ci.yml" ]] then
            echo "��������! ��� ����������� ������. ������� �� ����� ��� �������� � ���� �����"
            continue
        fi
        BranchName=($(echo $i | sed 's/.*;//' | grep -oP --regexp="$prefix\K\d+"))
        if [ "$BranchName" = "" ]
        then
            echo "$commit ��������! ������ ����� ��� ������"
            BranchName="NotTask"
        else
            BranchName=$prefix$BranchName
        fi
        echo "����� ��� ����� �� $commit: $BranchName"                           
        echo "����� ��� �������: $commit"
        echo "���������  ��������� � ����� ����"
        echo git checkout -B "feature/${BranchName}" "origin/feature/${BranchName}" || git checkout -B "feature/${BranchName}"
        echo git cherry-pick --keep-redundant-commits --strategy-option=recursive -X=theirs ${commit}
        if [[ "$DebugMode" != "True" ]] then
            git checkout -B "branch_sync_hran" "origin/branch_sync_hran"
            git checkout -B "feature/${BranchName}" "origin/feature/${BranchName}" || git checkout -B "feature/${BranchName}"
            git cherry-pick --keep-redundant-commits --strategy-option=recursive -X=theirs ${commit}
            git diff --name-only --diff-filter=U | xargs git rm -f
            git add .
            git commit -m "${committext}"
            git push --set-upstream origin "feature/${BranchName}"
        else
           echo "��������! ������� �����-����� � �������� � ����� �� ����������" 
        fi
    done

if [[ "$DebugMode" != "True" ]] then
    git reset
    git checkout -B "branch_sync_hran" "origin/branch_sync_hran"
    git merge "storage_1c"
    git push origin "branch_sync_hran"
fi
git checkout -B "storage_1c" "origin/storage_1c"

