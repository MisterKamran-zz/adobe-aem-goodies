package net.aimdigital.aemgoodies.taglibs;

import java.io.IOException;
import java.text.Format;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Dictionary;

import javax.servlet.jsp.tagext.TagSupport;

import org.apache.commons.lang3.StringUtils;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import tldgen.BodyContentType;
import tldgen.Tag;

@Tag(bodyContentType= BodyContentType.SCRIPTLESS)
public class CodebaseDetails extends TagSupport {

	private static final long serialVersionUID = 1L;
	
	private static final Logger LOGGER = LoggerFactory.getLogger(CodebaseDetails.class);
	
	private String version;
    private String modifiedDate;
	
	@Override
    public int doStartTag() {
    	
    	Bundle thisBundle = FrameworkUtil.getBundle(CodebaseDetails.class);
    	if (thisBundle != null) {
    		version = thisBundle.getVersion().toString();
    		modifiedDate = convertTime(thisBundle.getLastModified());
    	}
    	
    	StringBuilder bf = new StringBuilder();
    	bf.append("Codebase Version: ");
    	bf.append(version);
    	bf.append(" | ");
    	bf.append("Last Modified: ");
    	bf.append(modifiedDate);
    	bf.append(" | ");
    	bf.append("Git Branch: ");
    	bf.append(getGitBranchName(thisBundle));
        try {
			pageContext.getOut().print(bf.toString());
		} catch (IOException e) {
			LOGGER.error("Could not print codebase details.");
		}
        return SKIP_BODY;
    }
    
    @SuppressWarnings("unchecked")
    private String getGitBranchName(Bundle bundle) {
        Dictionary<String, String> dictionary = bundle.getHeaders();
        String gitBranch = dictionary.get("Git-Branch");
        if (StringUtils.isNotBlank(gitBranch)) {
            return gitBranch;
        } else {
            LOGGER.error("Git Branch not found in bundle manifest header.");
            return "";
        }
    }
    
    private String convertTime(long time){
        Date date = new Date(time);
        Format format = new SimpleDateFormat("dd-MM-yyyy HH:mm:ss");
        return format.format(date).toString();
    }

}
