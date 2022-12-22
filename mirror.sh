#!/bin/bash

PPA_PROJECTS="${PPA_PROJECTS##*( )}"
PPA_ENDPOINT_LAUNCHPAD=${PPA_ENDPOINT_LAUNCHPAD}
PPA_ENDPOINT_LAUNCHPADCONTENT=${PPA_ENDPOINT_LAUNCHPADCONTENT}
PPA_KEYS_ENDPOINT=${PPA_KEYS_ENDPOINT}
PPA_DISTROS=${PPA_DISTROS}
PPA_ARCHITECTURES=${PPA_ARCHITECTURES}
DOWNLOADS=/downloads

[[ -z "$PPA_PROJECTS" ]] && { echo "Parameter PPA_PROJECTS is empty" ; exit 1; }
[[ -z "$PPA_ENDPOINT_LAUNCHPAD" ]] && { echo "Parameter PPA_ENDPOINT_LAUNCHPAD is empty" ; exit 1; }
[[ -z "$PPA_ENDPOINT_LAUNCHPADCONTENT" ]] && { echo "Parameter PPA_ENDPOINT_LAUNCHPADCONTENT is empty" ; exit 1; }
[[ -z "$PPA_KEYS_ENDPOINT" ]] && { echo "Parameter PPA_KEYS_ENDPOINT is empty" ; exit 1; }
[[ -z "$PPA_DISTROS" ]] && { echo "Parameter PPA_DISTROS is empty" ; exit 1; }
[[ -z "$PPA_ARCHITECTURES" ]] && { echo "Parameter PPA_ARCHITECTURES is empty" ; exit 1; }

wget_m() {
    wget --mirror -q --show-progress -nH --cut-dirs=1 --convert-links --page-requisites --no-parent --reject='*.html*,*.gif*' "$1" -P "$2"
}

ppa_endpoint_launchpadcontent_domain=$(echo "${PPA_ENDPOINT_LAUNCHPADCONTENT}" | awk -F[/:] '{print $4}')
IFS="," read -ra projects <<< "$PPA_PROJECTS"
IFS="," read -ra distros <<< "$PPA_DISTROS"
IFS="," read -ra architectures <<< "$PPA_ARCHITECTURES"
for project in "${projects[@]}"; do
    ppa_project_author=$(echo "${project}" | cut -d'/' -f1)
    ppa_project_name=$(echo "${project}" | cut -d'/' -f2)
    ppa_author_directory="${DOWNLOADS}/${ppa_endpoint_launchpadcontent_domain}/${ppa_project_author}"
    ppa_project_directory="${ppa_author_directory}/${ppa_project_name}/ubuntu"
    mkdir -p "${ppa_project_directory}"
    ppa_project_endpoint="${PPA_ENDPOINT}/"
    ppa_remote_project_page_endpoint="${PPA_ENDPOINT_LAUNCHPAD}/~${ppa_project_author}/+archive/ubuntu/${ppa_project_name}"
    remote_pgp_key=$(wget "${ppa_remote_project_page_endpoint}" -q -O - | grep "<code>" | tr -d ' ' | awk '{ gsub("<[/]?code>", "", $0); print $0 }')
    ppa_project_pgp_hash=$(echo "${remote_pgp_key}" | cut -d'/' -f2)
    ppa_pgp_endpoint="${PPA_KEYS_ENDPOINT}?op=get&search=0x${ppa_project_pgp_hash}"
    wget "${ppa_pgp_endpoint}" -q -O - > "${ppa_project_directory}/${ppa_project_author}-${ppa_project_name}.pgp"
    ppa_mirror_endpoint="${PPA_ENDPOINT_LAUNCHPADCONTENT}/${ppa_project_author}/${ppa_project_name}/ubuntu"
    ppa_mirror_pool_endpoint="${ppa_mirror_endpoint}/pool"
    echo -e "${project}: Starting download of ${ppa_mirror_endpoint}..."
    for ppa_distro in "${distros[@]}"; do
        echo -e "${project}: Starting dists download for ${ppa_distro} (light)..."
        ppa_mirror_dists_endpoint="${ppa_mirror_endpoint}/dists/${ppa_distro}"
        ppa_mirror_dists_directory="${ppa_project_directory}/dists/${ppa_distro}"
        mkdir -p "$ppa_mirror_dists_directory"
        for file in "InRelease" "Release" "Release.gpg"
        do
            wget "$ppa_mirror_dists_endpoint/$file" -O "$ppa_mirror_dists_directory/$file"
        done
        wget_m "$ppa_mirror_dists_endpoint/by-hash/" "$ppa_author_directory/"
        for ppa_architecture in "${architectures[@]}"; do
            wget_m "$ppa_mirror_dists_endpoint/main/binary-${ppa_architecture}/" "$ppa_author_directory/"
            wget_m "$ppa_mirror_dists_endpoint/main/debian-installer/binary-${ppa_architecture}/" "$ppa_author_directory/"
        done
        wget_m "$ppa_mirror_dists_endpoint/main/i18n/" "$ppa_author_directory/"
        wget_m "$ppa_mirror_dists_endpoint/main/source/" "$ppa_author_directory/"
        echo -e "${project}: Finished dists download for ${ppa_distro}."
    done
    echo -e "${project}: Pool download (heavy)..."
    wget_m "$ppa_mirror_pool_endpoint/" "$ppa_author_directory/"
    echo -e "${project}: Finished download for ${ppa_mirror_endpoint}."
done
