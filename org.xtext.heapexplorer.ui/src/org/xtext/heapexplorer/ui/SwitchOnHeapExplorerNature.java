package org.xtext.heapexplorer.ui;

import org.apache.log4j.Logger;
import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.Command;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.xtext.util.Arrays;

public class SwitchOnHeapExplorerNature extends AbstractHandler {

	private static final Logger log = Logger.getLogger(SwitchOnHeapExplorerNature.class);
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		Command command = event.getCommand();
	    boolean oldValue = HandlerUtil.toggleCommandState(command); 
		Shell shell = HandlerUtil.getActiveShell(event);
	    ISelection sel = HandlerUtil.getActiveMenuSelection(event);
	    IStructuredSelection selection = (IStructuredSelection) sel;

	    Object firstElement = selection.getFirstElement();
	    if (firstElement instanceof IJavaProject) {
	    	IJavaProject prj = (IJavaProject) firstElement;
	    	
	    	try {
				IProjectDescription description = prj.getProject().getDescription();
				String[] natures = description.getNatureIds();
				String heapExplorerNature = "org.xtext.heapexplorer.HeapExplorerNature";
				String[] newNatures;
				if (Arrays.contains(natures, heapExplorerNature)) {
					log.error("0 POOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
					newNatures = new String[natures.length - 1];
				    int j = 0 ;
				    for (int i = 0 ; i < natures.length ; i++) {
				    	if (!heapExplorerNature.equals(natures[i])) {
				    		newNatures[j++] = natures[i];
				    	}
				    }
				}
				else {
					log.error("1 POOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
					newNatures = new String[natures.length + 1];
					System.arraycopy(natures, 0, newNatures, 0, natures.length);
				    newNatures[natures.length] = heapExplorerNature;
				}
			    
			    description.setNatureIds(newNatures);
			    prj.getProject().setDescription(description, null);
//			    IStatus status = workspace.validateNatureSet(newNatures);
			} catch (CoreException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
//	      
	    }		
//		

		
		return null;
	}

}
