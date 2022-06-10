#! /bin/bash

set -u

# calling process needs to set:
# $base
# $training_corpora
# $testing_corpora
# $local_download_data
# $zenodo_token_focusnews
# $zenodo_token_srf_poses
# $zenodo_token_srf_videos_subtitles

base=$1
training_corpora=$2
local_download_data=$3
testing_corpora=$4
zenodo_token_focusnews=$5
zenodo_token_srf_poses=$6
zenodo_token_srf_videos_subtitles=$7

scripts=$base/scripts
download=$base/download
venvs=$base/venvs

mkdir -p $download

# only download if user indicated they have *not* already downloaded elsewhere

for training_corpus in $training_corpora; do

    download_sub=$download/$training_corpus

    if [[ -d $download_sub ]]; then
          echo "download_sub already exists: $download_sub"
          echo "Skipping. Delete files to repeat step."
          continue
    fi

    if [[ $local_download_data == "false" ]]; then

        # then download the data from Zenodo

        if [[ $training_corpus == "focusnews" ]]; then

            download_sub_zenodo=$download_sub
            zenodo_deposit_id=6621480
            zenodo_token=$zenodo_token_focusnews

            . $scripts/downloading/download_zenodo_generic.sh
        else
            # assume training corpus is SRF

            # download poses

            download_sub_zenodo=$download_sub/zenodo_poses
            zenodo_deposit_id=6630145
            zenodo_token=$zenodo_token_srf_poses

            . $scripts/downloading/download_zenodo_generic.sh

            # download videos and subtitles

            download_sub_zenodo=$download_sub/zenodo_videos_subtitles
            zenodo_deposit_id="?"  # TODO
            zenodo_token=$zenodo_token_srf_videos_subtitles

            . $scripts/downloading/download_zenodo_generic.sh

            # finally combine data from both folders srf/zenodo_poses and srf/zenodo_videos_subtitles back into one

            mkdir $download_sub/parallel $download_sub/monolingual

            mv $download_sub/zenodo_videos_subtitles/parallel/videos $download_sub/parallel/
            mv $download_sub/zenodo_videos_subtitles/parallel/subtitles $download_sub/parallel/
            mv $download_sub/zenodo_videos_subtitles/monolingual/subtitles $download_sub/monolingual/

            mv $download_sub/zenodo_poses/parallel/openpose $download_sub/parallel/
            mv $download_sub/zenodo_poses/parallel/mediapipe $download_sub/parallel/

            rm -r $download_sub/zenodo_videos_subtitles
            rm -r $download_sub/zenodo_poses
        fi

    else
        # in that case link existing files

        corpus=$training_corpus

        . $scripts/downloading/download_link_folder_generic.sh
    fi
done

# download or link dev and test data if requested

for testing_corpus in $testing_corpora; do

    if [[ $testing_corpus == "dev_unseen" ]]; then
        corpus="dev"
    elif [[ $testing_corpus == "test_unseen" ]]; then
        # assume test
        corpus="test"
    fi

    download_sub=$download/$testing_corpus

    if [[ -d $download_sub ]]; then
          echo "download_sub already exists: $download_sub"
          echo "Skipping. Delete files to repeat step."
          continue
    fi

    mkdir -p $download_sub

    if [[ $local_download_data == "false" ]]; then

        # TODO: download dev and test data instead of also linking locally here
        corpus=$testing_corpus

        . $scripts/downloading/download_link_folder_generic.sh

    else
        # in that case link existing files

        corpus=$testing_corpus

        . $scripts/downloading/download_link_folder_generic.sh
    fi
done

echo "Sizes of files:"

ls -lh $download/*/*/*