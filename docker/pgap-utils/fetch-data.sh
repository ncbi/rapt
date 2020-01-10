#!/bin/bash
#
# TeamCity step Fetch binaries and third party data
#

set -uexo pipefail
TARFILE="$1"; shift
branch="$1"; shift # %teamcity.build.branch%
svn_revision="$1"; shift # %dep.GP_GpPgap2_Release.build.vcs.number.pgap_2%
svn_url="$1"; shift # %dep.GP_GpPgap2_Release.vcsroot.pgap_2.url% we always have this, even for origin/dev builds
# but we still rely on the fact that URL points to a link with actual branch
# svn pg svn:externals https://svn.ncbi.nlm.nih.gov/repos/toolkit/branches/gpipe/build/pgap 
# ncbi_cxx https://svn.ncbi.nlm.nih.gov/repos/toolkit/branches/gpipe/bacterial-pipeline/prod/4.10


case "$branch" in
    dev)
        cat > versions.json <<JSON_DEV
{
    "svn_url": null,
    "svn_revision": null,
    "branch_major_minor", null,
    "branch_major": null,
    "branch_minor": null
}    
JSON_DEV
    ;;
    prod|test)
        branch_major_minor=$(svn pg svn:externals "$svn_url" | 
        grep -Poh 'https://svn.ncbi.nlm.nih.gov/repos/toolkit/branches/gpipe/bacterial-pipeline/prod/\d+\.\d+'  |
        grep -Poh '\d+\.\d+')
        branch_major=$(echo "$branch_major_minor" | cut -f1 -d.)
        branch_minor=$(echo "$branch_major_minor" | cut -f2 -d.)

        cat > versions.json <<JSON
{   
    "svn_url": "$svn_url",
    "svn_revision": "$svn_revision",
    "branch_major_minor", "$branch_major_minor",
    "branch_major": "$branch_major",
    "branch_minor": "$branch_minor"
}
JSON
    ;;
esac

NEWTARFILE=install.tar.gz
tmpdir=tmp

sdir=$(dirname $(readlink -f "$0"))

#############################################################
#
# Config files for use by Docker
#
#############################################################

mkdir -p etc/yum.repos.d
cp /etc/yum.repos.d/ncbi.repo etc/yum.repos.d
cp /etc/toolkitrc etc
cp /etc/.ncbirc etc

#############################################################
#
# Binaries for use by Docker
#
#############################################################

binaries=binaries
rm -rf "$binaries"
mkdir "$binaries"

#############################################################
#
# Versioning
#
#############################################################



set +e
VERSION=$(tar -tf "$TARFILE" | head -n1 | cut -f1 -d/)
set -e
echo "$VERSION" > "$binaries/VERSION"

#
#
#

mkdir -p "$tmpdir"
tar \
    --exclude='*/setup' \
    --exclude='*/src.tar.gz' \
    -xvf "$TARFILE" -C "$tmpdir"
mv "$TARFILE" "$binaries/$NEWTARFILE"

mkdir -p "$binaries/bin"
cp -rL \
    "$tmpdir"/next/third-party/16S_submission/arch/x86_64/bin/* \
    "$tmpdir"/next/third-party/infernal/arch/x86_64/bin/* \
    "$tmpdir"/next/third-party/sparclbl/* \
    "$tmpdir"/next/third-party/GenomeColl/*/arch/x86_64/bin/gc_get_assembly \
    "$binaries/bin/"

# The following variable is now set in build-image.sh
#TRNASCAN_VERSION=2.0.4                    
#cat <<EOF
###teamcity[setParameter name='env.TRNASCAN_VERSION' value='${TRNASCAN_VERSION}']
#EOF

tar cvhpPf "$binaries"/trnascan.tgz /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE

set +e # temporarily, only until SYS fixes source tree
tar cvpPf infernal.tgz /usr/local/infernal/1.1.2
set -e



files=$(find $tmpdir/next/arch/x86_64/bin -maxdepth 1 -type f -not -name "*.p*" -not -name "*.txt" -not -name "*.ini" -print)
"$sdir"/package_dependencies.sh "$tmpdir"/next/arch/x86_64/bin $files
linked_exes=$(find $tmpdir/next/arch/x86_64/bin -maxdepth 1 -type l -print | 
             grep -f "$sdir/exe_links.whitelist" | 
             xargs ls -l | 
             cut -d'>' -f2 | 
             tr -d '\n')
tar cvPf "$binaries"/linked_exe.tar $linked_exes

#############################################################
#
# Shallow copy of supplemental data for use by PGAP CWL
#
#############################################################

input=input-links
rm -rf $input
mkdir -p $input

third_party_binary_source="$tmpdir/$VERSION/third-party"
third_party_data_source="$tmpdir/$VERSION/third-party/data"

#
#   shallow copy of symlinks...
#
cp -P $third_party_data_source/BacterialPipeline/16S_rRNA $input/
cp -P $third_party_data_source/BacterialPipeline/23S_rRNA $input/
cp -P $third_party_data_source/cdd_add $input/
cp -P $third_party_data_source/CDD2 $input/
#
#  ... with the exception of GeneMark: need to make sure that we do not drag extra subversions
#
mkdir $input/GeneMark
#
#   $genemark_version is hardcoded in classic PGAP's genemark.cpp, member variable m_GeneMarkPath
#   when it changes there we need to copy that here
#   Theoretically, we could have extracted src.tar.gz from input $TARBALL 
#   extracted genemark.cpp from there and
#   heuristically get the version from that source file,
#   but reliance on heuristic is not really better than relying on hardcoded version
#
genemark_version=ver2.110_114
cp -PLr $third_party_binary_source/GeneMark/"$genemark_version"  $input/GeneMark/


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
ln -s $(readlink -f /panfs/pan1/gpipe/bacterial_pipeline/system/current/etc/bacterial_pipeline/rfam-amendments.xml )  $input/

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
#  synonym table
#
ln -s /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/jira/PGAPX-585-save-ProkRefseqTracking-TaxSynon/TaxSynon.tsv $input/  # WE NEED A PROCESS TO GET THIS
ln -s /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/jira/PGAPX-584-ani_top_identification-needs-to-/GCExtract2.sqlite $input/  # WE NEED A PROCESS TO GET THIS
#
#   miscellanious files
#
ln -s /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/dev/automated_builds/installations/regr_bct/current/third-party/data/BacterialPipeline/ANI_cutoff/ANI_cutoff.xml $input/
#
#   copy right away, we are already dealing here with a copy
#
cp $tmpdir/$VERSION/etc/product_rules.prt $input/
cp $tmpdir/$VERSION/etc/thresholds.xml $input/
cp $tmpdir/$VERSION/etc/validation-results.xml $input/
cp $tmpdir/$VERSION/etc/asn2pas.xsl $input/
cp $tmpdir/$VERSION/etc/ani-report.xsl $input/

#
#   WARNING: unversioned source! We are not currently using it. It is used in a dead-end cache_entrez_gene step
#
cp /panfs/pan1.be-md.ncbi.nlm.nih.gov/refgene/LOCUS/bin/genes/inifiles/gene_master.ini $input/

#############################################################
#
# Cleanup
#
#############################################################
chmod -R u+w $tmpdir
rm -rf $tmpdir
