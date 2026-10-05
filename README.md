# Orchestra
This repository contains tools and information related to the [Orchestra Standard](https://fixtrading.org/standards/orchestra/) developed by the [FIX Trading Community](https://fixtrading.org/). The objective is to provide free tools under the Apache 2.0 licence that are useful to the financial community. These tools should not have to be implemented more than once and this repository intends to act as a hub and invites others to contribute.

Electronic interfaces defined with Orchestra are machine-readable XML files. They can be visualised with [Orchimate](https://orchimate.org/), a browser tool offered free of charge by the FIX member firm [Atomic Wire](https://www.atomicwire.io/).

## Transform QuickFIX to Orchestra
The XSLT script `quickfix2orchestra.xsl` takes a standard QuickFIX data dictionary (XML file) and transforms it to an Orchestra V1.0 XML file (names of element references are added for convenience and will be supported by Orchestra v1.1). It is intended to jump start the process of using Orchestra for an existing FIX interface that has been implemented with QuickFIX. Once generated, the Orchestra XML files can be loaded into local memory with [Orchimate](https://orchimate.org/).

The bash script `quickfix2orchestra.sh` is available to run the XSLT script under a UNIX-based OS. It expects the filename as first, a keyword for the FIX version as second, and the name of the Orchestra metadata file as third parameter. The QuickFIX file must be in a subfolder "input" and the Orchestra file will be generated in a subfolder "output". The metadata file must be in the subfolder "lookup" and can be changed to reflect the actual creator, dates etc. Usage example (bash):

`$./quick2orchestra.sh QFDD-FIX42 FIX42 metadata`

The FIX version parameter is used to pick the appropriate file with the list of numerical message, group, and component identifiers since QuickFIX files do not have this information. The version keywords "FIX42", "FIX44", and "FIXLatest" are pre-defined but are merely used to create the file names "lookup/Orchestra<FIX version>-messages/groups/components.txt". The keyword can actually be any string as long as the respective files exist in the subfolder "lookup". The txt-files need to contain the names of all messages, groups, and components used in teh QuickFIX file, including custom elements. Custom fields must have a tag number in QuickFIX and are treated no different from standard fields. There is intentionally no validation against an official reference file from FIX. That could be subject to a different tool that compares the Orchestra representation of the QuickFIX data dictionary against the official Orchestra XML file for FIX 4.2, FIX 4.4 or FIX Latest.

Orchestra code sets and codes require numerical identifiers. The identifiers of code sets are defined by the tag number of the field using the code set. The code identifiers are defined by concatenating the code set identifier and a 3-digit suffix (starting with "001"). This is the standard approach in FIX Latest.

Note that QuickFIX does not support the use of enumerated field values across multiple fields, e.g. PartyRole(452) and NestedPartyRole(538). Each field must have its own list of enumerated values attached to it. The script will create an Orchestra code set for every field defined with one or more enumerated values. Manual post-processing is required to use the Orchestra-native possibility of assigning the same code set to two or more fields.

QuickFIX data dictionaries for FIX 4.2, FIX 4.4, and FIX Latest are provided as examples in the folder "input" as well as the resulting Orchestra XML files in the folder "output".

Note that the script adds the names of groups, components, fields referenced in messages, groups, components for convenience. This is not part of Orchestra V1.0 but will be supported with Orchestra V1.1.

## Transform FIXML to Orchestra
The XSLT script `fixml2orchestra.xsl` takes a standard QuickFIX data dictionary (XML file) and transforms it to an Orchestra V1.0 XML file  (names of element references are added for convenience and will be supported by Orchestra v1.1). It is intended to jump start the process of using Orchestra for an existing FIX interface that uses FIXML encoding. Once generated, the Orchestra XML files can be loaded into local memory with [Orchimate](https://orchimate.org/).

With the exception of fields, all element types are sorted by name in the generated Orchestra XML file. The reason is that identifiers do not play any role in a FIXML encoding, but are required by Orchestra. The scripts looks up the element IDs by using the element names found in the FIXML schema files. NoXXX fields and the StandardTrailer component are not needed by FIXML but still generated. This can be useful when transitioning from FIXML to a different encoding such as TagValue. Session Layer messages are not applicable to FIXML and not generated.

The bash script `fixml2orchestra.sh` is available to run the XSLT script under a UNIX-based OS. It expects a keyword for the FIX version as first parameter followed by an EP number and the name of the Orchestra metadata file as second and third parameter. The FIXML schema files must be in a subfolder "input/fixml" and the Orchestra file will be generated in a subfolder "output". The metadata file must be in the subfolder "lookup" and can be changed to reflect the actual creator, dates etc. Usage example (bash):

`$./fixml2orchestra.sh FIXLatest metadata`

## Extract elements from Orchestra
The XSLT script `extractElement.xsl` creates separate text files with a list of identifiers and names for each Orchestra element type with a numerical identifier. The tool can be used to create lookup tables as input for other tools. The bash script `extractElement.sh` is available to run the XSLT script under a UNIX-based OS. It takes the filename (may include a full path) as parameter and creates txt-files in the folder "target" (created if absent and ignored by GitHub). The following information is provided in the output columns (separated by a single space).

- Messages: ID, name, mesage type (attribute `msgType`)
- Groups: ID, name, ID of numInGroup field
- Components: ID, name
- Fields: ID, name
- Code sets: ID, name
- Codes: ID, name (a.k.a. symbolic name)

Note that Orchestra scenarios are not supported, i.e. duplicates are removed. Scenarios are quite unique to Orchestra and not applicable for lookup tables to generate Orchestra XML files from other schemas that do not have such a concept.
