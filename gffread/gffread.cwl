#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  InlineJavascriptRequirement:
    expressionLib:
    - var get_output_filename = function() {
            if (inputs.output_filename == ""){
              var ext = ".fa";
              var root = inputs.genome_fasta_file.basename.split('.').slice(0,-1).join('.');
              return (root == "")?inputs.genome_fasta_file.basename+ext:root+ext;
            } else {
              return inputs.output_filename;
            }
          };

hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gffread:0.11.7--h8b12597_0
  SoftwareRequirement:
    packages:
      gffread:
        specs: [ https://bio.tools/gffread ]

inputs:
  genome_fasta_file:
    type: File
    format: edam:format_1929  # FASTA
    secondaryFiles:
      - .fai
    inputBinding:
      position: 5
      prefix: "-g"
    doc: "Genome file in FASTA format, uncompressed"

  annotation_gtf_file:
    type: File
    format: edam:format_2306  # GTF
    inputBinding:
      position: 10
    doc: "GTF annotation file"

  output_filename:
    type: string?
    inputBinding:
      position: 6
      prefix: "-w"
      valueFrom: $(get_output_filename())
    default: ""
    doc: "Filename for generated transcriptome FASTA file"

outputs:
  transcriptome_fasta_file:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: $(get_output_filename())

baseCommand: gffread

$namespaces:
  s: http://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/

$schemas:
- https://schema.org/version/latest/schemaorg-current-https.rdf

s:name: "gffread"
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
  Generates a FASTA file with the DNA sequences for all transcripts in a GFF file
