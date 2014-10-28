package org.xtext.heapexplorer.natures;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.apache.log4j.Logger;
import org.eclipse.core.resources.ICommand;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IProjectNature;
import org.eclipse.core.runtime.CoreException;

public class HeapExplorerNature implements IProjectNature {

	private IProject project;

	private static final Logger log = Logger
			.getLogger(HeapExplorerNature.class);

	final static String BUILDER_COPY_ID = "org.xtext.heapexplorer.copycoresources";
	final static String BUILDER_COMPILE_ID = "org.xtext.heapexplorer.compileAnalysis";
	
	
	@Override
	public void configure() throws CoreException {
		if (project == null)
			return;

		IProjectDescription desc = project.getDescription();
		ICommand[] commands = desc.getBuildSpec();
		boolean found = false;

		for (int i = 0; i < commands.length; ++i) {
			if (commands[i].getBuilderName().equals(BUILDER_COPY_ID)) {
				found = true;
				break;
			}
		}
		if (!found) {
			// add builders to project
			List<ICommand> newCommands = new LinkedList<ICommand>(Arrays.asList(commands));
			
			// add builder to copy needed files
			ICommand command = desc.newCommand();
			command.setBuilderName(BUILDER_COPY_ID);
			newCommands.add(0, command); //
			
			// add builder to compile source code
			command = desc.newCommand();
			command.setBuilderName(BUILDER_COMPILE_ID);
			newCommands.add(command);
			
			// add builders to he description of the project
			desc.setBuildSpec(newCommands.toArray(new ICommand[newCommands.size()]));
			project.setDescription(desc, null);
		}
	}

	@Override
	public void deconfigure() throws CoreException {
		// remove builder with BUILDER_COPY_ID 
		removeBuilder(BUILDER_COPY_ID);
		// remove builder with BUILDER_COPY_ID 
		removeBuilder(BUILDER_COMPILE_ID);
	}

	private void removeBuilder(String builderID) throws CoreException {
		IProjectDescription desc = project.getDescription();
		ICommand[] commands = desc.getBuildSpec();
		int i = 0;
		for (i = 0; i < commands.length; ++i) {
			if (commands[i].getBuilderName().equals(builderID)) {
				break;
			}
		}
		if (i < commands.length) {
			ICommand[] newCommands = new ICommand[commands.length - 1];

			// remove it
			System.arraycopy(commands, 0, newCommands, 0, i);
			System.arraycopy(commands, i+1, newCommands, i, commands.length - (i + 1));
			desc.setBuildSpec(newCommands);
			project.setDescription(desc, null);
		}
	}

	@Override
	public IProject getProject() {
		return project;
	}

	@Override
	public void setProject(IProject project) {
		this.project = project;
	}

}
