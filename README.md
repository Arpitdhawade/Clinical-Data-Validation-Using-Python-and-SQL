# Clinical-Data-Validation-Using-Python-and-SQL
# Clinical Trial Data Validation: BRCA301

A comprehensive SDTM data cleaning and validation project demonstrating regulatory-compliant clinical data management practices.

## Project Overview

This project validates data from a Phase III breast cancer trial (BRCA301), implementing CDISC SDTM standards and FDA data integrity requirements.

## What Makes This Different

Unlike typical data cleaning projects, this demonstrates:
- ✅ **Clinical context:** Every validation rule includes clinical rationale
- ✅ **No data fabrication:** Flags issues rather than imputing/deleting
- ✅ **CDISC standards:** Full SDTM IG 3.4 conformance
- 
## Technical Highlights

### Validation Framework
- SDTM conformance checking (required variables, formats, lengths)
- Controlled terminology validation (CDISC-CT, MedDRA)
- Cross-domain referential integrity
- Clinical business rules (protocol criteria, safety thresholds)
- Date logic validation

### Tools Used
- **SQL (PostgreSQL):** Data profiling and transformation
- **Python (pandas):** Validation logic and quality metrics
- **Pinnacle 21:** Industry-standard validation tool
- **Git:** Version control and documentation

## Project Structure
