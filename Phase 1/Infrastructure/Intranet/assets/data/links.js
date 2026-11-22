(function (ns) { ns.Data = ns.Data || {};
ns.Data.Links=[
{title:"Corporate announcements",category:"Corporate resources",description:"Read fictional company notices.",route:"news.html",external:false},
{title:"Employee directory",category:"Corporate resources",description:"Search fictional employee records.",route:"employee-directory.html",external:false},
{title:"Systems status",category:"IT resources",description:"View demonstration service status.",route:"system-status.html",external:false},
{title:"Knowledge Base",category:"IT resources",description:"Browse safe sample support guidance.",route:"knowledge-base.html",external:false},
{title:"People Center",category:"HR resources",description:"Review demonstration HR guidance.",route:"hr-resources.html",external:false},
{title:"Policies & Procedures",category:"HR resources",description:"Search fictional approved and draft policies.",route:"policies.html",external:false},
{title:"Infrastructure overview",category:"Cloud and data resources",description:"Review sanitized fictional platforms.",route:"infrastructure.html",external:false},
{title:"Applications catalog",category:"Cloud and data resources",description:"Find application ownership and access guidance.",route:"applications.html",external:false},
{title:"Learning resources",category:"Training",description:"Review fictional learning paths.",route:"hr-resources.html#learning",external:false},
{title:"Security awareness",category:"Training",description:"Read suspicious-email guidance.",route:"knowledge-base.html?article=KB-1003",external:false},
{title:"Service Desk",category:"Support",description:"Validate a demonstration IT request.",route:"service-desk.html",external:false},
{title:"Contact IT",category:"Support",description:"Find placeholder support and escalation channels.",route:"contact-support.html",external:false}
];
ns.Data.Forms=[
{name:"Access request",purpose:"Request role-based access to a demonstration application.",audience:"Employees and approved contractors",required:"Application, business purpose, manager",process:"Owner and manager review",status:"Demonstration"},
{name:"Software request",purpose:"Request approved desktop or server software.",audience:"Employees",required:"Software, device, business purpose",process:"License and security review",status:"Demonstration"},
{name:"Hardware request",purpose:"Request standard workplace hardware.",audience:"Employees",required:"Equipment, location, justification",process:"Manager and asset review",status:"Demonstration"},
{name:"Purchase request",purpose:"Initiate a fictional purchase review.",audience:"Authorized employees",required:"Supplier, amount, cost center",process:"Budget and procurement review",status:"Placeholder"},
{name:"Travel request",purpose:"Record proposed business travel.",audience:"Employees",required:"Destination, dates, purpose",process:"Manager and travel review",status:"Placeholder"},
{name:"Leave request",purpose:"Record requested time away.",audience:"Employees",required:"Dates, leave type",process:"Manager and HR review",status:"Placeholder"},
{name:"New employee setup",purpose:"Coordinate standard onboarding activities.",audience:"Hiring managers",required:"Start date, role, equipment, access",process:"HR, IT and manager tasks",status:"Demonstration"},
{name:"Employee offboarding",purpose:"Coordinate access and asset closure.",audience:"Managers and HR",required:"End date, assets, access owners",process:"HR, Security and IT tasks",status:"Demonstration"},
{name:"Marketing approval",purpose:"Request review of a fictional marketing asset.",audience:"Marketing team",required:"Asset, audience, publication date",process:"Brand and legal review",status:"Placeholder"},
{name:"IT change request",purpose:"Propose a controlled technical change.",audience:"Technology teams",required:"Scope, risk, test and rollback plan",process:"Technical and change review",status:"Demonstration"}
];
}(window.GrandMachinato = window.GrandMachinato || {}));