#!/bin/bash
#
#  Prepares input files using currently selected global version manifest
#
#   the details of linking, copying and on-the-fly editing of input files here are intrically related 
#   to input.yaml
#
#
sdir=$(dirname $(readlink -f $0))
source $sdir/global_version_file_tools.source

global_version_file="$1"; shift
home="$1"; shift

set -euxo pipefail

if [ "$home" = "" ]; then
    echo "usage: $0 global_version_file home" >&2
    die "Specify all params" 
fi
global_version=$(get_global_version "$global_version_file")
input="$home/$global_version/input-links"
rm -rf $input
mkdir -p $input
TC_VERSION=$(get_tc_version "$global_version_file")
tc_build_tag="${TC_VERSION}:id"

wget -N https://teamcity.ncbi.nlm.nih.gov/guestAuth/repository/download/GP_DEV_SoftwareCompilationArtifactGeneration_ReleaseWoDependencies/$tc_build_tag/install.prod.tar.gz
set +e
VERSION=`tar -tf install.prod.tar.gz | head -n1 | cut -f1 -d/`
set -e
tar xzf install.prod.tar.gz
third_party_binary_source="$VERSION/third-party"
third_party_data_source="$VERSION/third-party/data"

#
#   shallow copy of symlinks
#

cp -P $third_party_data_source/BacterialPipeline/16S_rRNA $input/
cp -P $third_party_data_source/BacterialPipeline/23S_rRNA $input/
cp -P $third_party_data_source/cdd_add $input/
cp -P $third_party_data_source/CDD $input/
cp -P $third_party_binary_source/GeneMark  $input/


#
#   symlink/readlink with maybe preliminary mkdir
#
rm -f $input/uniColl_path
mkdir -p $input/uniColl_path
ln -s $(readlink -f $third_party_data_source/BacterialPipeline/uniColl/current)/* $input/uniColl_path/
mkdir -p $input/uniColl_path/blast_dir
mv $input/uniColl_path/NamingDatabase.* $input/uniColl_path/blast_dir
ln -s $(readlink -f $third_party_data_source/Rfam/pgap-3.1/CMs/RF00001.cm) $input/
ln -s $(readlink -f $third_party_data_source/Rfam/pgap-3.1/Rfam.selected1.cm)  $input/
ln -s $(readlink -f $third_party_data_source/Rfam/pgap-3.1/Rfam.seed)  $input/
ln -s $(readlink -f $third_party_data_source/BacterialPipeline/Rfam/rfam-amendments.xml)  $input/

mkdir -p $input/AntiFamLib
ln -s $(readlink -f $third_party_data_source/AntiFam/AntiFam_Unidentified.hmm) $input/AntiFamLib/ 
ln -s $(readlink -f $third_party_data_source/AntiFam/AntiFam_Bacteria.hmm) $input/AntiFamLib/ 

ln -s $(readlink -f $third_party_data_source/BacterialPipeline/uniColl/current/blast_rule_protein.gilist.bin) $input/uniColl_path/blast_dir
perl -pe '
                $_="DBLIST NamingDatabase\n" if /^DBLIST/;
                $_="GILIST blast_rule_protein.gilist.bin\n" if /^GILIST/;
' $third_party_data_source/BacterialPipeline/uniColl/current/BlastRules.pal > $input/uniColl_path/blast_dir/blast_rules_db.pal

ln -s $(readlink -f $third_party_data_source/BacterialPipeline/uniColl/current/NamingDatabase.pal) $input/uniColl_path/blast_dir/blastdb.pal

mkdir -p $input/selenoproteins
ln -s  $(readlink -f $third_party_data_source/BacterialPipeline/Selenoproteins)/selenoproteins* $input/selenoproteins/
cat > $input/selenoproteins/blastdb.pal <<SELENOPROTEINS
TITLE BLAST database for selenoproteins
DBLIST selenoproteins
SELENOPROTEINS

#
#   copy right away, we are already dealing here with a copy
#

cp $VERSION/etc/product_rules.prt $input/
cp $VERSION/etc/thresholds.xml $input/
cp $VERSION/etc/validation-results.xml $input/
cp $VERSION/etc/asn2pas.xsl $input/

#
#   WARNING: unversioned source! We are not currently using it. It is used in a dead-end cache_entrez_gene step
#
cp /panfs/pan1.be-md.ncbi.nlm.nih.gov/refgene/LOCUS/bin/genes/inifiles/gene_master.ini $input/


