#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool


requirements:
  InlineJavascriptRequirement:
    expressionLib:
    - var get_label = function(i) {
          var rootname = inputs.gex_molecule_info_h5[i].basename.split('.').slice(0,-1).join('.');
          rootname = (rootname=="")?inputs.gex_molecule_info_h5[i].basename:rootname;
          return inputs.gem_well_labels?inputs.gem_well_labels[i].replace(/\t|\s|\[|\]|\>|\<|,|\./g, "_"):rootname;
      };
  InitialWorkDirRequirement:
    listing: |
      ${
        var entry = "library_id,atac_fragments,per_barcode_metrics,gex_molecule_info\n"
        for (var i=0; i < inputs.gex_molecule_info_h5.length; i++){
          entry += get_label(i) + "," + inputs.atac_fragments_file[i].path + "," + inputs.barcode_metrics_report[i].path + "," + inputs.gex_molecule_info_h5[i].path + "\n"
        }
        return [{
          "entry": entry,
          "entryname": "metadata.csv"
        }];
      }
hints:
  DockerRequirement:
    dockerPull: cumulusprod/cellranger-arc:2.0.0

inputs:
  atac_fragments_file:
    type: File[]
    format: iana:text/tab-separated-values
    secondaryFiles:
    - .tbi
    doc: |
      Array of files containing count and barcode information for every ATAC
      fragment observed in the experiment in TSV format. Outputs from
      "cellranger-arc count" command.

  barcode_metrics_report:
    type: File[]
    doc: |
      Array of files with the ATAC and GEX read count summaries generated for every
      barcode observed in the experiment. Outputs from "cellranger-arc count" command.

  gex_molecule_info_h5:
    type: File[]
    format: edam:format_3590  # HDF5
    doc: |
      Array of GEX molecule-level information files in HDF5 format.
      Outputs from "cellranger-arc count" command.

  gem_well_labels:
    type:
    - "null"
    - string[]
    doc: |
      Array of GEM well identifiers to be used for labeling purposes only.
      If not provided use rootnames of files from the gex_molecule_info_h5
      input

  indices_folder:
    type: Directory
    inputBinding:
      position: 5
      prefix: "--reference"
    doc: |
      Compatible with Cell Ranger ARC reference folder that includes
      STAR and BWA indices. Should be generated by "cellranger-arc mkref"
      command

  normalization_mode:
    type:
    - "null"
    - type: enum
      name: "normalization"
      symbols: ["none", "depth"]
    inputBinding:
      position: 6
      prefix: "--normalize"
    doc: |
      Library depth normalization mode: depth, none.
      Default: depth

  threads:
    type: int?
    inputBinding:
      position: 7
      prefix: "--localcores"
    doc: |
      Set max cores the pipeline may request at one time.
      Default: all available

  memory_limit:
    type: int?
    inputBinding:
      position: 8
      prefix: "--localmem"
    doc: |
      Set max GB the pipeline may request at one time
      Default: all available

  virt_memory_limit:
    type: int?
    inputBinding:
      position: 9
      prefix: "--localvmem"
    doc: |
      Set max virtual address space in GB for the pipeline
      Default: all available


outputs:

  web_summary_report:
    type: File
    format: iana:text/html
    outputBinding:
      glob: "aggregated/outs/web_summary.html"
    doc: |
      Aggregated run summary metrics and charts in HTML format

  metrics_summary_report:
    type: File
    format: iana:text/csv
    outputBinding:
      glob: "aggregated/outs/summary.csv"
    doc: |
      Aggregated run summary metrics in CSV format

  atac_fragments_file:
    type: File
    format: iana:text/tab-separated-values
    outputBinding:
      glob: "aggregated/outs/atac_fragments.tsv.gz"
    secondaryFiles:
    - .tbi
    doc: |
      Count and barcode information for every ATAC fragment observed in the
      aggregated experiment in TSV format

  atac_peaks_bed_file:
    type: File
    format: edam:format_3003  # BED
    outputBinding:
      glob: "aggregated/outs/atac_peaks.bed"
    doc: |
      Locations of open-chromatin regions identified in aggregated experiment
      (these regions are referred to as "peaks")

  atac_peak_annotation_file:
    type: File
    format: iana:text/tab-separated-values
    outputBinding:
      glob: "aggregated/outs/atac_peak_annotation.tsv"
    doc: |
      Annotations of peaks based on genomic proximity alone (for aggregated
      experiment). Note that these are not functional annotations and they
      do not make use of linkage with GEX data.

  secondary_analysis_report_folder:
    type: Directory
    outputBinding:
      glob: "aggregated/outs/analysis"
    doc: |
      Folder with secondary analysis results including dimensionality reduction,
      cell clustering, and differential expression for aggregated results

  filtered_feature_bc_matrix_folder:
    type: Directory
    outputBinding:
      glob: "aggregated/outs/filtered_feature_bc_matrix"
    doc: |
      Folder with aggregated filtered feature-barcode matrices containing only
      cellular barcodes in MEX format

  filtered_feature_bc_matrix_h5:
    type: File
    format: edam:format_3590  # HDF5
    outputBinding:
      glob: "aggregated/outs/filtered_feature_bc_matrix.h5"
    doc: |
      Aggregated filtered feature-barcode matrices containing only cellular barcodes
      in HDF5 format

  raw_feature_bc_matrices_folder:
    type: Directory
    outputBinding:
      glob: "aggregated/outs/raw_feature_bc_matrix"
    doc: |
      Folder with aggregated unfiltered feature-barcode matrices containing all barcodes
      in MEX format

  raw_feature_bc_matrices_h5:
    type: File
    format: edam:format_3590  # HDF5
    outputBinding:
      glob: "aggregated/outs/raw_feature_bc_matrix.h5"
    doc: |
      Aggregated unfiltered feature-barcode matrices containing all barcodes
      in HDF5 format

  aggregation_metadata:
    type: File
    format: iana:text/csv
    outputBinding:
      glob: "aggregated/outs/aggr.csv"
    doc: |
      Copy of the input aggregation CSV file

  loupe_browser_track:
    type: File
    outputBinding:
      glob: "aggregated/outs/cloupe.cloupe"
    doc: |
      Loupe Browser visualization and analysis file for aggregated results

baseCommand: ["cellranger-arc", "aggr", "--disable-ui", "--id", "aggregated", "--csv", "metadata.csv"]

$namespaces:
  s: http://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

label: "Cellranger ARC aggr - aggregates data from multiple Cellranger ARC runs"
s:alternateName: "Cellranger ARC aggr takes a list of cellranger ARC count output files and produces a single feature-barcode matrix containing all the data"

s:license: http://www.apache.org/licenses/LICENSE-2.0

s:creator:
- class: s:Organization
  s:legalName: "Cincinnati Children's Hospital Medical Center"
  s:location:
  - class: s:PostalAddress
    s:addressCountry: "USA"
    s:addressLocality: "Cincinnati"
    s:addressRegion: "OH"
    s:postalCode: "45229"
    s:streetAddress: "3333 Burnet Ave"
    s:telephone: "+1(513)636-4200"
  s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"
  s:department:
  - class: s:Organization
    s:legalName: "Allergy and Immunology"
    s:department:
    - class: s:Organization
      s:legalName: "Barski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotliar
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898


doc: |

  Tool calls "cellranger-arc aggr" command that takes as input a CSV file specifying a list
  of cellranger-arc count output files for each GEM well being aggregated and produces a
  single feature-barcode matrix containing all the data. When combining multiple GEM wells,
  the barcode sequences for each channel are distinguished by a GEM well suffix appended to
  the barcode sequence. By default, the reads from each GEM well are subsampled such that all
  GEM wells have the same effective sequencing depth for both ATAC and gene expression modalities;
  for the ATAC data it is measured in terms of median unique fragments per cell and for gene
  expression it is measured in terms of the average number of reads that are confidently mapped
  to the transcriptome per cell. However, it is possible to turn off this normalization altogether.

  Parameters set by default:
  --disable-ui - no need in any UI when running in Docker container
  --id - hardcoded to `aggregated` as we want to return the content of the
         outputs folder as separate outputs

  Skipped parameters:
  --nosecondary
  --dry
  --noexit
  --nopreflight
  --description
  --peaks
  --jobmode
  --mempercore
  --maxjobs
  --jobinterval
  --overrides
  --uiport