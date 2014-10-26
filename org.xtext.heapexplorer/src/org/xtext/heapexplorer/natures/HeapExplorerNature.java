package org.xtext.heapexplorer.natures;

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

	final String BUILDER_ID = "org.xtext.heapexplorer.copycoresources";
	
	
	@Override
	public void configure() throws CoreException {
		log.error("EL COCO SE REGISTRA");
		if (project == null)
			return;

		IProjectDescription desc = project.getDescription();
		ICommand[] commands = desc.getBuildSpec();
		boolean found = false;

		for (int i = 0; i < commands.length; ++i) {
			if (commands[i].getBuilderName().equals(BUILDER_ID)) {
				found = true;
				break;
			}
		}
		if (!found) {
			// add builder to project
			ICommand command = desc.newCommand();
			command.setBuilderName(BUILDER_ID);
			ICommand[] newCommands = new ICommand[commands.length + 1];

			// Add it before other builders.
			System.arraycopy(commands, 0, newCommands, 1, commands.length);
			newCommands[0] = command;
			desc.setBuildSpec(newCommands);
			project.setDescription(desc, null);
		}
	}

	@Override
	public void deconfigure() throws CoreException {
		log.error("EL COCO SE DEREGISTRA");
		IProjectDescription desc = project.getDescription();
		ICommand[] commands = desc.getBuildSpec();

		int i = 0;
		for (i = 0; i < commands.length; ++i) {
			if (commands[i].getBuilderName().equals(BUILDER_ID)) {
				break;
			}
		}
		if (i < commands.length) {
			ICommand[] newCommands = new ICommand[commands.length - 1];

			// remove it before other builders.
			System.arraycopy(commands, 0, newCommands, 0, i);
			System.arraycopy(commands, i+1, newCommands, i, commands.length - (i + 1));
			desc.setBuildSpec(newCommands);
			project.setDescription(desc, null);
		}
	}

	@Override
	public IProject getProject() {
		// TODO Auto-generated method stub
		return project;
	}

	@Override
	public void setProject(IProject project) {
		this.project = project;
	}

}
