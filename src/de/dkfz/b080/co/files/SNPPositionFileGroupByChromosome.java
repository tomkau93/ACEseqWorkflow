/*
 * Copyright (c) 2017 The ACEseq workflow developers.
 *
 * Distributed under the MIT License (license terms are at https://www.github.com/eilslabs/ACEseqWorkflow/LICENSE.txt).
 */

package de.dkfz.b080.co.files;
import de.dkfz.b080.co.aceseq.*;

import de.dkfz.roddy.execution.jobs.ScriptCallingMethod;
import de.dkfz.roddy.knowledge.files.FileGroup;
import de.dkfz.roddy.knowledge.methods.GenericMethod;

import java.util.LinkedList;
import java.util.Map;

/**
 */
public class SNPPositionFileGroupByChromosome extends FileGroup {

    private Map<String, SNPPositionFile> files;

    public SNPPositionFileGroupByChromosome(Map<String, SNPPositionFile> files) {
        super(new LinkedList<>(files.values()));
        this.files = files;
    }

    public Map<String, SNPPositionFile> getFiles() {
        return files;
    }

    @ScriptCallingMethod
    public TextFile mergeAndFilter() {
        BamFile bf = (BamFile)(files.get("1")).getParentFiles().get(0); //Should be merged tumor bam file
        TextFile file = GenericMethod.callGenericTool(ACEseqConstants.TOOL_MERGE_AND_FILTER_SNP_FILES, bf, this);
        return file;
    }
}
