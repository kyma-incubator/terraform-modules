resource_group = attribute('resource_group')
cluster_name = attribute('cluster_name')

control "aks-001" do
  impact 1.0
  title "Validating aks"
  describe azurerm_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
  end
end
