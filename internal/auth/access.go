// Copyright © 2018 Banzai Cloud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package auth

import (
	"github.com/casbin/casbin"
)

// AccessManager is responsible for managing authorization rules.
type AccessManager struct {
	enforcer *casbin.SyncedEnforcer
	basePath string
}

// NewAccessManager returns a new AccessManager instance.
func NewAccessManager(enforcer *casbin.SyncedEnforcer, basePath string) *AccessManager {
	return &AccessManager{
		enforcer: enforcer,
		basePath: basePath,
	}
}

// AddDefaultPolicies adds default policy rules to the underlying access manager.
func (m *AccessManager) AddDefaultPolicies() {
	m.enforcer.AddPolicy("default", m.basePath+"/api/v1/allowed/secrets", "*")
	m.enforcer.AddPolicy("default", m.basePath+"/api/v1/allowed/secrets/*", "*")
	m.enforcer.AddPolicy("default", m.basePath+"/api/v1/orgs", "*")
	m.enforcer.AddPolicy("default", m.basePath+"/api/v1/token", "*")
	m.enforcer.AddPolicy("default", m.basePath+"/api/v1/tokens", "*")
	m.enforcer.AddPolicy("defaultVirtual", m.basePath+"/api/v1/orgs", "GET")
}

// AddDefaultRoleToUser adds all the default non-org-specific role to a user.
func (m *AccessManager) AddDefaultRoleToUser(userID string) {
	m.enforcer.AddRoleForUser(userID, "default")
}

// AddDefaultRoleToVirtualUser adds org list role to a virtual user.
func (m *AccessManager) AddDefaultRoleToVirtualUser(userID string) {
	m.enforcer.AddRoleForUser(userID, "defaultVirtual")
}